package com.sentinel.sdk.mobfacil

/**
 * Configuration options for the MobFácil Keycloak OAuth2 & KrakenD Gateway pipeline.
 */
data class MobfacilAuthConfig(
    val baseUrl: String = DEFAULT_BASE_URL,
    val tokenEndpoint: String = DEFAULT_TOKEN_ENDPOINT,
    val dataEndpoint: String = DEFAULT_DATA_ENDPOINT,
    val clientId: String = DEFAULT_CLIENT_ID,
    val clientSecret: String = DEFAULT_CLIENT_SECRET,
    val grantType: String = DEFAULT_GRANT_TYPE,
    val renewalBufferSeconds: Long = DEFAULT_RENEWAL_BUFFER_SECONDS,
    val requestTimeoutSeconds: Long = DEFAULT_TIMEOUT_SECONDS,
    val dnsFallbackHost: String = DEFAULT_FALLBACK_HOST,
    val dnsFallbackIp: String = DEFAULT_FALLBACK_IP,
    val dnsFallbackEnabled: Boolean = true
) {
    companion object {
        const val DEFAULT_BASE_URL = "https://api.stg.mobfacil.com.br"
        const val DEFAULT_TOKEN_ENDPOINT = "/login/token"
        const val DEFAULT_DATA_ENDPOINT = "/telemetry"
        const val DEFAULT_CLIENT_ID = "sdk_ken_QA"
        const val DEFAULT_CLIENT_SECRET = "nkO2atoPD3po2U3vPYQz8m8V1LXq84fU"
        const val DEFAULT_GRANT_TYPE = "client_credentials"
        const val DEFAULT_RENEWAL_BUFFER_SECONDS = 60L
        const val DEFAULT_TIMEOUT_SECONDS = 30L
        const val DEFAULT_FALLBACK_HOST = "api.stg.mobfacil.com.br"
        const val DEFAULT_FALLBACK_IP = "65.21.200.181"
    }

    fun getFullTokenUrl(): String {
        return resolveUrl(tokenEndpoint)
    }

    fun getFullDataUrl(): String {
        return resolveUrl(dataEndpoint)
    }

    private fun resolveUrl(endpoint: String): String {
        if (endpoint.startsWith("http://") || endpoint.startsWith("https://")) {
            return endpoint
        }
        val cleanBase = baseUrl.trimEnd('/')
        val cleanEndpoint = endpoint.trimStart('/')
        return "$cleanBase/$cleanEndpoint"
    }
}

