package com.sentinel.sdk.mobfacil

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.Dns
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.net.InetAddress
import java.net.UnknownHostException
import java.util.concurrent.TimeUnit

/**
 * Resilient DNS resolver intercepting host resolution.
 * When standard system DNS throws UnknownHostException on international CNAME delegation chains,
 * it returns the designated fallback IP while preserving the original hostname for TLS SNI.
 */
class MobfacilDns(
    private val fallbackHost: String = MobfacilAuthConfig.DEFAULT_FALLBACK_HOST,
    private val fallbackIp: String = MobfacilAuthConfig.DEFAULT_FALLBACK_IP,
    private val fallbackEnabled: Boolean = true,
    private val systemLookup: (String) -> List<InetAddress> = { Dns.SYSTEM.lookup(it) }
) : Dns {

    override fun lookup(hostname: String): List<InetAddress> {
        return try {
            val systemResult = systemLookup(hostname)
            if (systemResult.isNotEmpty()) {
                systemResult
            } else if (fallbackEnabled && hostname.equals(fallbackHost, ignoreCase = true)) {
                resolveFallback(hostname)
            } else {
                throw UnknownHostException("No address found for $hostname")
            }
        } catch (e: UnknownHostException) {
            if (fallbackEnabled && hostname.equals(fallbackHost, ignoreCase = true)) {
                resolveFallback(hostname)
            } else {
                throw e
            }
        }
    }

    private fun resolveFallback(hostname: String): List<InetAddress> {
        val rawIp = InetAddress.getByName(fallbackIp).address
        return listOf(InetAddress.getByAddress(hostname, rawIp))
    }
}

/**
 * HTTP response data container.
 */
data class MobfacilHttpResponse(
    val statusCode: Int,
    val headers: Map<String, String>,
    val body: String?,
    val rawBytes: ByteArray?
)

/**
 * HTTP network transport abstraction.
 */
interface MobfacilHttpTransport {
    suspend fun execute(
        url: String,
        method: String = "GET",
        headers: Map<String, String> = emptyMap(),
        body: ByteArray? = null,
        contentType: String? = null
    ): MobfacilHttpResponse
}

/**
 * Production OkHttp transport with resilient DNS fallback and SNI preservation.
 */
class OkHttpMobfacilTransport(
    private val config: MobfacilAuthConfig,
    client: OkHttpClient? = null
) : MobfacilHttpTransport {

    private val okHttpClient: OkHttpClient = client ?: OkHttpClient.Builder()
        .dns(
            MobfacilDns(
                fallbackHost = config.dnsFallbackHost,
                fallbackIp = config.dnsFallbackIp,
                fallbackEnabled = config.dnsFallbackEnabled
            )
        )
        .connectTimeout(config.requestTimeoutSeconds, TimeUnit.SECONDS)
        .readTimeout(config.requestTimeoutSeconds, TimeUnit.SECONDS)
        .writeTimeout(config.requestTimeoutSeconds, TimeUnit.SECONDS)
        .build()

    override suspend fun execute(
        url: String,
        method: String,
        headers: Map<String, String>,
        body: ByteArray?,
        contentType: String?
    ): MobfacilHttpResponse = withContext(Dispatchers.IO) {
        val requestBody = body?.toRequestBody(contentType?.toMediaTypeOrNull())

        val requestBuilder = Request.Builder()
            .url(url)
            .method(method, requestBody)

        for ((key, value) in headers) {
            requestBuilder.header(key, value)
        }

        val response = okHttpClient.newCall(requestBuilder.build()).execute()
        val responseBodyBytes = response.body?.bytes()
        val responseBodyString = responseBodyBytes?.let { String(it, Charsets.UTF_8) }

        val responseHeaders = mutableMapOf<String, String>()
        for (i in 0 until response.headers.size) {
            responseHeaders[response.headers.name(i)] = response.headers.value(i)
        }

        MobfacilHttpResponse(
            statusCode = response.code,
            headers = responseHeaders,
            body = responseBodyString,
            rawBytes = responseBodyBytes
        )
    }
}

typealias MockRequestHandler = (url: String, method: String, headers: Map<String, String>, body: ByteArray?) -> MobfacilHttpResponse

/**
 * Mock transport for unit testing without live network connections.
 */
class MockMobfacilHttpTransport : MobfacilHttpTransport {

    private val handlers = mutableMapOf<String, MockRequestHandler>()
    private var defaultHandler: MockRequestHandler? = null
    val executedRequests = mutableListOf<RecordedRequest>()

    data class RecordedRequest(
        val url: String,
        val method: String,
        val headers: Map<String, String>,
        val body: ByteArray?
    )

    fun registerHandler(pathOrUrl: String, handler: MockRequestHandler) {
        handlers[pathOrUrl] = handler
    }

    fun setDefaultHandler(handler: MockRequestHandler) {
        defaultHandler = handler
    }

    fun clearRequests() {
        executedRequests.clear()
    }

    override suspend fun execute(
        url: String,
        method: String,
        headers: Map<String, String>,
        body: ByteArray?,
        contentType: String?
    ): MobfacilHttpResponse {
        val recorded = RecordedRequest(url, method, headers, body)
        executedRequests.add(recorded)

        val uriPath = try {
            java.net.URI(url).path
        } catch (e: Exception) {
            url
        }

        val handler = handlers[url] ?: handlers[uriPath] ?: defaultHandler
        return handler?.invoke(url, method, headers, body)
            ?: throw MobfacilAuthException.NetworkException("No mock handler found for request to: $url")
    }
}
