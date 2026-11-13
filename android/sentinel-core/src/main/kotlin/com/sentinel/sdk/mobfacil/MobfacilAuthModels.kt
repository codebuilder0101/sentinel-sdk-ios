package com.sentinel.sdk.mobfacil

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Keycloak OAuth2 access token representation and state tracking.
 */
@Serializable
data class MobfacilToken(
    @SerialName("access_token") val accessToken: String,
    @SerialName("expires_in") val expiresIn: Int,
    @SerialName("token_type") val tokenType: String = "Bearer",
    @SerialName("refresh_expires_in") val refreshExpiresIn: Int? = 0,
    @SerialName("created_at_ms") val createdAtMs: Long = System.currentTimeMillis(),
    @SerialName("expires_at_ms") val expiresAtMs: Long = createdAtMs + (expiresIn * 1000L)
) {
    fun remainingSeconds(nowMs: Long = System.currentTimeMillis()): Long {
        return (expiresAtMs - nowMs) / 1000L
    }

    fun isExpired(nowMs: Long = System.currentTimeMillis()): Boolean {
        return remainingSeconds(nowMs) <= 0L
    }

    fun isExpiringSoon(bufferSeconds: Long = 60L, nowMs: Long = System.currentTimeMillis()): Boolean {
        return remainingSeconds(nowMs) <= bufferSeconds
    }
}

/**
 * Raw Keycloak OAuth2 error response body.
 */
@Serializable
data class MobfacilOAuthErrorResponse(
    @SerialName("error") val error: String,
    @SerialName("error_description") val errorDescription: String? = null
)

/**
 * Domain-specific exceptions mapped to lifecycle conditions.
 */
sealed class MobfacilAuthException(message: String, cause: Throwable? = null) : Exception(message, cause) {

    /**
     * Flow 4: Inadimplência / Suspended License (mapped from invalid_client).
     */
    data class LicenseBlocked(val description: String) :
        MobfacilAuthException("Licença bloqueada por inadimplência: $description")

    /**
     * Flow 5: Secret Rotated or Compromised (mapped from unauthorized_client).
     */
    data class UnauthorizedClient(val description: String) :
        MobfacilAuthException("Credenciais inválidas ou secret rotacionado: $description")

    /**
     * HTTP error with status code and body.
     */
    data class HttpException(val statusCode: Int, val body: String?) :
        MobfacilAuthException("Erro HTTP $statusCode: ${body ?: "sem conteúdo"}")

    /**
     * Network transport or connection error.
     */
    data class NetworkException(override val message: String, override val cause: Throwable? = null) :
        MobfacilAuthException(message, cause)

    /**
     * Token parsing, missing, or validation error.
     */
    data class TokenException(override val message: String) :
        MobfacilAuthException(message)

    /**
     * DNS resolution failure.
     */
    data class DnsResolutionException(val host: String) :
        MobfacilAuthException("Falha ao resolver DNS para $host")
}

/**
 * Collector transmission response.
 */
@Serializable
data class MobfacilCollectorResponse(
    @SerialName("status_code") val statusCode: Int,
    @SerialName("success") val success: Boolean,
    @SerialName("tracking_id") val trackingId: String? = null,
    @SerialName("message") val message: String? = null,
    @SerialName("timestamp_ms") val timestampMs: Long = System.currentTimeMillis(),
    val rawBody: String? = null
)

