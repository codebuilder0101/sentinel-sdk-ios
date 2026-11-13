package com.sentinel.sdk.mobfacil

import com.sentinel.sdk.models.SentinelPayload
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * Service managing serialization, Bearer authentication header injection,
 * gateway transmission, and the Flow 2 Alt (401 Retry) recovery loop.
 */
class MobfacilCollectorService(
    val config: MobfacilAuthConfig = MobfacilAuthConfig(),
    val tokenManager: MobfacilTokenManager,
    private val transport: MobfacilHttpTransport
) {
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    /**
     * Transmits a captured SentinelPayload to the KrakenD telemetry gateway.
     */
    suspend fun transmit(
        payload: SentinelPayload,
        endpoint: String? = null
    ): MobfacilCollectorResponse {
        val jsonString = json.encodeToString(payload)
        return transmit(jsonString = jsonString, endpoint = endpoint)
    }

    /**
     * Transmits raw JSON string with Bearer token authentication and 401 retry handling.
     */
    suspend fun transmit(
        jsonString: String,
        endpoint: String? = null
    ): MobfacilCollectorResponse {
        val targetUrl = resolveTargetUrl(endpoint)

        // 1. Acquire current valid token (Flow 1 / Flow 3)
        val token = tokenManager.getValidToken()

        // 2. Prepare headers with Bearer token (Flow 2)
        val headers = mutableMapOf(
            "Content-Type" to "application/json",
            "Accept" to "application/json",
            "Authorization" to "${token.tokenType} ${token.accessToken}"
        )

        val bodyBytes = jsonString.toByteArray(Charsets.UTF_8)

        // 3. Transmit payload
        val response = transport.execute(
            url = targetUrl,
            method = "POST",
            headers = headers,
            body = bodyBytes,
            contentType = "application/json"
        )

        // 4. Handle 200..299 Success
        if (response.statusCode in 200..299) {
            return parseSuccessResponse(response.statusCode, response.body)
        }

        // 5. Handle Flow 2 Alt: 401 Unauthorized (Token expired in flight)
        if (response.statusCode == 401) {
            // Invalidate cached token immediately
            tokenManager.invalidateToken()

            // Force fresh token renewal
            val freshToken = tokenManager.getValidToken(forceRefresh = true)

            // Retry data transmission once with new Bearer token
            val retryHeaders = headers.toMutableMap().apply {
                this["Authorization"] = "${freshToken.tokenType} ${freshToken.accessToken}"
            }

            val retryResponse = transport.execute(
                url = targetUrl,
                method = "POST",
                headers = retryHeaders,
                body = bodyBytes,
                contentType = "application/json"
            )

            if (retryResponse.statusCode in 200..299) {
                return parseSuccessResponse(retryResponse.statusCode, retryResponse.body)
            } else {
                throw MobfacilAuthException.HttpException(retryResponse.statusCode, retryResponse.body)
            }
        }

        // 6. Other non-2xx status codes
        throw MobfacilAuthException.HttpException(response.statusCode, response.body)
    }

    private fun resolveTargetUrl(endpoint: String?): String {
        if (endpoint == null) return config.getFullDataUrl()
        if (endpoint.startsWith("http://") || endpoint.startsWith("https://")) {
            return endpoint
        }
        val cleanBase = config.baseUrl.trimEnd('/')
        val cleanEndpoint = endpoint.trimStart('/')
        return "$cleanBase/$cleanEndpoint"
    }

    private fun parseSuccessResponse(statusCode: Int, responseBody: String?): MobfacilCollectorResponse {
        var trackingId: String? = null
        var message: String? = null

        if (!responseBody.isNullOrBlank()) {
            try {
                val jsonElement = json.parseToJsonElement(responseBody)
                if (jsonElement is JsonObject) {
                    trackingId = jsonElement["tracking_id"]?.jsonPrimitive?.content
                        ?: jsonElement["id"]?.jsonPrimitive?.content
                    message = jsonElement["message"]?.jsonPrimitive?.content
                        ?: jsonElement["status"]?.jsonPrimitive?.content
                }
            } catch (_: Exception) {
                // If body is not JSON object, fallback to default
            }
        }

        return MobfacilCollectorResponse(
            statusCode = statusCode,
            success = true,
            trackingId = trackingId,
            message = message,
            timestampMs = System.currentTimeMillis(),
            rawBody = responseBody
        )
    }
}

