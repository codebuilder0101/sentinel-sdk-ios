package com.sentinel.sdk

import com.sentinel.sdk.mobfacil.InMemoryMobfacilTokenStorage
import com.sentinel.sdk.mobfacil.MobfacilAuthConfig
import com.sentinel.sdk.mobfacil.MobfacilAuthException
import com.sentinel.sdk.mobfacil.MobfacilCollectorService
import com.sentinel.sdk.mobfacil.MobfacilDns
import com.sentinel.sdk.mobfacil.MobfacilHttpResponse
import com.sentinel.sdk.mobfacil.MobfacilToken
import com.sentinel.sdk.mobfacil.MobfacilTokenManager
import com.sentinel.sdk.mobfacil.MockMobfacilHttpTransport
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import java.net.InetAddress
import java.net.UnknownHostException
import java.util.UUID

class MobfacilAuthTests {

    private val sampleAccessToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.android_sample_token"
    private val sampleNewAccessToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.android_renewed_token"

    // MARK: - Flow 1: Company Authentication Tests

    @Test
    fun testFlow1_CompanyAuthenticationSuccessAndPersistence() = runBlocking {
        val mockTransport = MockMobfacilHttpTransport()
        val config = MobfacilAuthConfig()
        val storage = InMemoryMobfacilTokenStorage()

        mockTransport.registerHandler("/login/token") { _, method, headers, body ->
            assertEquals("POST", method)
            assertEquals("application/x-www-form-urlencoded", headers["Content-Type"])
            assertEquals("application/json", headers["Accept"])

            val bodyString = body?.let { String(it, Charsets.UTF_8) } ?: ""
            assertTrue(bodyString.contains("grant_type=client_credentials"))
            assertTrue(bodyString.contains("client_id=sdk_ken_QA"))
            assertTrue(bodyString.contains("client_secret=nkO2atoPD3po2U3vPYQz8m8V1LXq84fU"))

            val jsonResponse = """
            {
                "access_token": "$sampleAccessToken",
                "expires_in": 300,
                "token_type": "Bearer",
                "refresh_expires_in": 0
            }
            """
            MobfacilHttpResponse(
                statusCode = 200,
                headers = mapOf("Content-Type" to "application/json"),
                body = jsonResponse,
                rawBytes = jsonResponse.toByteArray(Charsets.UTF_8)
            )
        }

        val tokenManager = MobfacilTokenManager(config, storage, mockTransport)
        val token = tokenManager.getValidToken()

        assertEquals(sampleAccessToken, token.accessToken)
        assertEquals(300, token.expiresIn)
        assertEquals("Bearer", token.tokenType)
        assertFalse(token.isExpired())
        assertFalse(token.isExpiringSoon(60L))
        assertTrue(token.remainingSeconds() > 280L)

        // Verify storage persistence
        val persisted = storage.loadToken()
        assertNotNull(persisted)
        assertEquals(sampleAccessToken, persisted?.accessToken)

        // Verify restart reuse
        mockTransport.clearRequests()
        val newManagerAfterRestart = MobfacilTokenManager(config, storage, mockTransport)
        val reusedToken = newManagerAfterRestart.getValidToken()
        assertEquals(sampleAccessToken, reusedToken.accessToken)
        assertEquals(0, mockTransport.executedRequests.size)
    }

    // MARK: - Flow 2: Data Transmission with Bearer Token

    @Test
    fun testFlow2_DataTransmissionWithBearerToken() = runBlocking {
        val mockTransport = MockMobfacilHttpTransport()
        val config = MobfacilAuthConfig()
        val initialToken = MobfacilToken(
            accessToken = sampleAccessToken,
            expiresIn = 300,
            tokenType = "Bearer"
        )
        val storage = InMemoryMobfacilTokenStorage(initialToken)
        val tokenManager = MobfacilTokenManager(config, storage, mockTransport)

        var capturedAuthHeader: String? = null
        var capturedBody: String? = null

        mockTransport.registerHandler("/telemetry") { _, _, headers, body ->
            capturedAuthHeader = headers["Authorization"]
            assertEquals("application/json", headers["Content-Type"])
            assertEquals("application/json", headers["Accept"])
            capturedBody = body?.let { String(it, Charsets.UTF_8) }

            val responseBody = """
            {
                "status_code": 200,
                "tracking_id": "trk_android_123",
                "message": "Telemetry received successfully"
            }
            """
            MobfacilHttpResponse(
                statusCode = 200,
                headers = mapOf("Content-Type" to "application/json"),
                body = responseBody,
                rawBytes = responseBody.toByteArray(Charsets.UTF_8)
            )
        }

        val collector = MobfacilCollectorService(config, tokenManager, mockTransport)
        val payloadJson = "{\"device_id\":\"pixel6pro\",\"os\":\"android17\"}"
        val response = collector.transmit(jsonString = payloadJson)

        assertTrue(response.success)
        assertEquals(200, response.statusCode)
        assertEquals("trk_android_123", response.trackingId)
        assertEquals("Bearer $sampleAccessToken", capturedAuthHeader)
        assertEquals(payloadJson, capturedBody)
    }

    // MARK: - Flow 2 Alt: 401 Retry on Token Expired in Flight

    @Test
    fun testFlow2Alt_401RetryFlow() = runBlocking {
        val mockTransport = MockMobfacilHttpTransport()
        val config = MobfacilAuthConfig()

        val expiredToken = MobfacilToken(
            accessToken = "expired_token_in_flight",
            expiresIn = 300,
            tokenType = "Bearer",
            createdAtMs = System.currentTimeMillis() - 350_000L,
            expiresAtMs = System.currentTimeMillis() + 50_000L
        )
        val storage = InMemoryMobfacilTokenStorage(expiredToken)
        val tokenManager = MobfacilTokenManager(config, storage, mockTransport)

        var telemetryAttemptCount = 0

        mockTransport.registerHandler("/login/token") { _, _, _, _ ->
            val jsonResponse = """
            {
                "access_token": "$sampleNewAccessToken",
                "expires_in": 300,
                "token_type": "Bearer",
                "refresh_expires_in": 0
            }
            """
            MobfacilHttpResponse(
                statusCode = 200,
                headers = mapOf("Content-Type" to "application/json"),
                body = jsonResponse,
                rawBytes = jsonResponse.toByteArray(Charsets.UTF_8)
            )
        }

        mockTransport.registerHandler("/telemetry") { _, _, headers, _ ->
            telemetryAttemptCount++
            val authHeader = headers["Authorization"]

            if (telemetryAttemptCount == 1) {
                assertEquals("Bearer expired_token_in_flight", authHeader)
                val errorBody = "{\"error\": \"unauthorized\", \"message\": \"Token has expired\"}"
                MobfacilHttpResponse(
                    statusCode = 401,
                    headers = mapOf("Content-Type" to "application/json"),
                    body = errorBody,
                    rawBytes = errorBody.toByteArray(Charsets.UTF_8)
                )
            } else {
                assertEquals("Bearer $sampleNewAccessToken", authHeader)
                val successBody = "{\"status_code\": 200, \"tracking_id\": \"retry_success_android\"}"
                MobfacilHttpResponse(
                    statusCode = 200,
                    headers = mapOf("Content-Type" to "application/json"),
                    body = successBody,
                    rawBytes = successBody.toByteArray(Charsets.UTF_8)
                )
            }
        }

        val collector = MobfacilCollectorService(config, tokenManager, mockTransport)
        val response = collector.transmit(jsonString = "{\"data\":\"test_payload\"}")

        assertTrue(response.success)
        assertEquals(200, response.statusCode)
        assertEquals("retry_success_android", response.trackingId)
        assertEquals(2, telemetryAttemptCount)

        val currentToken = tokenManager.getValidToken()
        assertEquals(sampleNewAccessToken, currentToken.accessToken)
    }

    // MARK: - Flow 3: Expiration Math & Concurrency Safety

    @Test
    fun testFlow3_ExpirationMath() {
        val now = System.currentTimeMillis()

        // 120s remaining
        val healthyToken = MobfacilToken(
            accessToken = "healthy",
            expiresIn = 300,
            tokenType = "Bearer",
            createdAtMs = now - 180_000L,
            expiresAtMs = now + 120_000L
        )
        assertFalse(healthyToken.isExpired(now))
        assertFalse(healthyToken.isExpiringSoon(60L, now))
        assertEquals(120L, healthyToken.remainingSeconds(now))

        // 45s remaining (<= 60s)
        val expiringSoonToken = MobfacilToken(
            accessToken = "expiring_soon",
            expiresIn = 300,
            tokenType = "Bearer",
            createdAtMs = now - 255_000L,
            expiresAtMs = now + 45_000L
        )
        assertFalse(expiringSoonToken.isExpired(now))
        assertTrue(expiringSoonToken.isExpiringSoon(60L, now))
        assertEquals(45L, expiringSoonToken.remainingSeconds(now))

        // 0s remaining (expired)
        val expiredToken = MobfacilToken(
            accessToken = "expired",
            expiresIn = 300,
            tokenType = "Bearer",
            createdAtMs = now - 300_000L,
            expiresAtMs = now
        )
        assertTrue(expiredToken.isExpired(now))
        assertTrue(expiredToken.isExpiringSoon(60L, now))
        assertTrue(expiredToken.remainingSeconds(now) <= 0L)
    }

    @Test
    fun testFlow3_ConcurrencySafetySingleInFlightRenewal() = runBlocking {
        val mockTransport = MockMobfacilHttpTransport()
        val config = MobfacilAuthConfig()
        val storage = InMemoryMobfacilTokenStorage()

        var tokenRequestCounter = 0

        mockTransport.registerHandler("/login/token") { _, _, _, _ ->
            synchronized(this) {
                tokenRequestCounter++
            }
            Thread.sleep(50)

            val jsonResponse = """
            {
                "access_token": "coalesced_token_${UUID.randomUUID()}",
                "expires_in": 300,
                "token_type": "Bearer",
                "refresh_expires_in": 0
            }
            """
            MobfacilHttpResponse(
                statusCode = 200,
                headers = mapOf("Content-Type" to "application/json"),
                body = jsonResponse,
                rawBytes = jsonResponse.toByteArray(Charsets.UTF_8)
            )
        }

        val tokenManager = MobfacilTokenManager(config, storage, mockTransport)

        // Launch 15 concurrent coroutines simultaneously requesting a token
        val concurrentCallers = 15
        val tasks = (1..concurrentCallers).map {
            async {
                tokenManager.getValidToken(forceRefresh = true)
            }
        }

        val tokens = tasks.awaitAll()
        assertEquals(concurrentCallers, tokens.size)

        val firstToken = tokens.first().accessToken
        for (token in tokens) {
            assertEquals(firstToken, token.accessToken)
        }

        assertEquals(1, tokenRequestCounter)
    }

    // MARK: - Flow 4: Inadimplência / Suspended License (invalid_client)

    @Test
    fun testFlow4_InadimplenciaSuspendedLicenseMapping() = runBlocking {
        val mockTransport = MockMobfacilHttpTransport()
        val config = MobfacilAuthConfig()
        val storage = InMemoryMobfacilTokenStorage()

        mockTransport.registerHandler("/login/token") { _, _, _, _ ->
            val errorJson = """
            {
                "error": "invalid_client",
                "error_description": "Invalid client or Invalid client credentials"
            }
            """
            MobfacilHttpResponse(
                statusCode = 400,
                headers = mapOf("Content-Type" to "application/json"),
                body = errorJson,
                rawBytes = errorJson.toByteArray(Charsets.UTF_8)
            )
        }

        val tokenManager = MobfacilTokenManager(config, storage, mockTransport)

        try {
            tokenManager.getValidToken()
            fail("Should have thrown MobfacilAuthException.LicenseBlocked")
        } catch (e: MobfacilAuthException.LicenseBlocked) {
            assertTrue(e.message!!.contains("Licença bloqueada por inadimplência"))
            assertTrue(e.description.contains("Invalid client"))
        } catch (e: Exception) {
            fail("Unexpected exception: ${e::class.java}")
        }
    }

    // MARK: - Flow 5: Secret Rotated or Compromised (unauthorized_client)

    @Test
    fun testFlow5_SecretRotatedOrCompromisedMapping() = runBlocking {
        val mockTransport = MockMobfacilHttpTransport()
        val config = MobfacilAuthConfig()
        val storage = InMemoryMobfacilTokenStorage()

        mockTransport.registerHandler("/login/token") { _, _, _, _ ->
            val errorJson = """
            {
                "error": "unauthorized_client",
                "error_description": "Invalid client or Invalid client credentials"
            }
            """
            MobfacilHttpResponse(
                statusCode = 401,
                headers = mapOf("Content-Type" to "application/json"),
                body = errorJson,
                rawBytes = errorJson.toByteArray(Charsets.UTF_8)
            )
        }

        val tokenManager = MobfacilTokenManager(config, storage, mockTransport)

        try {
            tokenManager.getValidToken()
            fail("Should have thrown MobfacilAuthException.UnauthorizedClient")
        } catch (e: MobfacilAuthException.UnauthorizedClient) {
            assertTrue(e.message!!.contains("Credenciais inválidas ou secret rotacionado"))
            assertTrue(e.description.contains("Invalid client"))
        } catch (e: Exception) {
            fail("Unexpected exception: ${e::class.java}")
        }
    }

    // MARK: - Resilient DNS Fallback

    @Test
    fun testDNSFallback_ResolverFallbackOnUnknownHostException() {
        val mobfacilDns = MobfacilDns(
            fallbackHost = "api.stg.mobfacil.com.br",
            fallbackIp = "65.21.200.181",
            fallbackEnabled = true,
            systemLookup = { _ ->
                throw UnknownHostException("Simulated DNS resolution failure on Brazilian CNAME")
            }
        )

        val resolvedAddresses = mobfacilDns.lookup("api.stg.mobfacil.com.br")
        assertEquals(1, resolvedAddresses.size)

        val address = resolvedAddresses.first()
        assertEquals("api.stg.mobfacil.com.br", address.hostName)
        assertEquals("65.21.200.181", address.hostAddress)
    }
}

