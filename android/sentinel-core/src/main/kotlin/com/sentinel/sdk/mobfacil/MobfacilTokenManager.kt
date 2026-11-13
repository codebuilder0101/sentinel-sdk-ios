package com.sentinel.sdk.mobfacil

import android.net.Uri
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.Json
import java.net.URLEncoder

/**
 * Thread-safe token manager coordinating Keycloak authentication, proactive renewal,
 * storage persistence, concurrency locking, and business error mapping.
 */
class MobfacilTokenManager(
    val config: MobfacilAuthConfig = MobfacilAuthConfig(),
    private val storage: MobfacilTokenStorage,
    private val transport: MobfacilHttpTransport
) {
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val mutex = Mutex()
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    @Volatile
    private var cachedToken: MobfacilToken? = null

    @Volatile
    private var inFlightRenewal: Deferred<MobfacilToken>? = null

    /**
     * Retrieves an unexpired access token.
     * @param forceRefresh When true, bypasses memory/storage cache and forces a fresh request.
     */
    suspend fun getValidToken(forceRefresh: Boolean = false): MobfacilToken {
        if (!forceRefresh) {
            val token = getCachedOrPersistedToken()
            if (token != null && !token.isExpired()) {
                // Flow 3: Proactive background renewal when remainingSeconds <= bufferSeconds (60s)
                if (token.isExpiringSoon(config.renewalBufferSeconds)) {
                    triggerProactiveBackgroundRenewal()
                }
                return token
            }
        }

        // Token is missing, expired, or forced refresh is requested.
        return executeOrCoalesceRenewal()
    }

    /**
     * Triggers asynchronous proactive background renewal without blocking the caller.
     */
    fun triggerProactiveBackgroundRenewal() {
        scope.launch {
            try {
                executeOrCoalesceRenewal()
            } catch (_: Exception) {
                // Background renewal failure is non-fatal since existing token is still valid
            }
        }
    }

    /**
     * Authenticates directly using client_credentials grant type.
     */
    suspend fun authenticate(): MobfacilToken {
        return executeOrCoalesceRenewal()
    }

    /**
     * Invalidates cached and persisted tokens.
     */
    suspend fun invalidateToken() {
        mutex.withLock {
            cachedToken = null
            storage.clearToken()
        }
    }

    fun getCachedToken(): MobfacilToken? = cachedToken

    // MARK: - Private Helpers

    private suspend fun getCachedOrPersistedToken(): MobfacilToken? {
        cachedToken?.let { return it }
        val persisted = storage.loadToken()
        if (persisted != null) {
            cachedToken = persisted
            return persisted
        }
        return null
    }

    /**
     * Concurrency Safety: Mutex lock ensuring concurrent callers share a single in-flight renewal job.
     */
    private suspend fun executeOrCoalesceRenewal(): MobfacilToken {
        val existingJob = mutex.withLock {
            inFlightRenewal
        }
        if (existingJob != null && existingJob.isActive) {
            return existingJob.await()
        }

        val deferred = mutex.withLock {
            // Re-check inside lock
            inFlightRenewal?.takeIf { it.isActive } ?: run {
                val newJob = scope.async {
                    try {
                        val token = requestTokenFromIdp()
                        cachedToken = token
                        storage.saveToken(token)
                        token
                    } finally {
                        mutex.withLock {
                            if (inFlightRenewal == this) {
                                inFlightRenewal = null
                            }
                        }
                    }
                }
                inFlightRenewal = newJob
                newJob
            }
        }

        return deferred.await()
    }

    private suspend fun requestTokenFromIdp(): MobfacilToken {
        val formBody = buildString {
            append("grant_type=").append(URLEncoder.encode(config.grantType, "UTF-8"))
            append("&client_id=").append(URLEncoder.encode(config.clientId, "UTF-8"))
            append("&client_secret=").append(URLEncoder.encode(config.clientSecret, "UTF-8"))
        }

        val headers = mapOf(
            "Content-Type" to "application/x-www-form-urlencoded",
            "Accept" to "application/json"
        )

        val response = transport.execute(
            url = config.getFullTokenUrl(),
            method = "POST",
            headers = headers,
            body = formBody.toByteArray(Charsets.UTF_8),
            contentType = "application/x-www-form-urlencoded"
        )

        // Flow 1: 200 OK
        if (response.statusCode in 200..299) {
            val responseBody = response.body
                ?: throw MobfacilAuthException.TokenException("Empty response body from IDP token endpoint")
            return try {
                json.decodeFromString<MobfacilToken>(responseBody)
            } catch (e: Exception) {
                throw MobfacilAuthException.TokenException("Failed to decode token JSON: ${e.message}")
            }
        }

        // Map Keycloak OAuth2 error responses (400 / 401)
        val bodyText = response.body ?: ""
        val errorResponse = try {
            json.decodeFromString<MobfacilOAuthErrorResponse>(bodyText)
        } catch (_: Exception) {
            null
        }

        if (errorResponse != null) {
            val errType = errorResponse.error.lowercase()
            val desc = errorResponse.errorDescription ?: bodyText

            // Flow 4: Inadimplência / Suspended License
            if (errType == "invalid_client") {
                throw MobfacilAuthException.LicenseBlocked(desc)
            }

            // Flow 5: Secret Rotated or Compromised
            if (errType == "unauthorized_client") {
                throw MobfacilAuthException.UnauthorizedClient(desc)
            }
        }

        throw MobfacilAuthException.HttpException(response.statusCode, bodyText)
    }
}

