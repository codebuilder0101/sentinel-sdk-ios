package com.sentinel.sdk

import com.sentinel.sdk.collectors.AppDetectionCollector
import com.sentinel.sdk.collectors.PersonalDataValidator
import com.sentinel.sdk.models.SentinelCoordinates
import com.sentinel.sdk.models.SentinelDeviceData
import com.sentinel.sdk.models.SentinelInstalledApps
import com.sentinel.sdk.models.SentinelLocationData
import com.sentinel.sdk.models.SentinelMetadata
import com.sentinel.sdk.models.SentinelPayload
import com.sentinel.sdk.models.SentinelSecurityData
import com.sentinel.sdk.models.SentinelTelephonyData
import com.sentinel.sdk.models.SentinelUserData
import com.sentinel.sdk.models.SentinelUserValidation
import com.sentinel.sdk.security.PayloadSigner
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class SentinelSDKTests {

    // MARK: - Personal Data Validation Tests

    @Test
    fun testPersonalDataValidationSuccess() {
        val validator = PersonalDataValidator()
        val input = PersonalDataValidator.Input(
            fullName = "Carlos Eduardo da Silva",
            documentId = "123.456.789-09", // Valid CPF check digits
            email = "carlos@example.com",
            phoneNumber = "+5511999998888"
        )
        val result = validator.validate(input)

        assertEquals("Carlos Eduardo da Silva", result.fullName)
        assertTrue(result.validation.isValid)
        assertTrue(result.validation.nameFormatValid)
        assertTrue(result.validation.documentValid)
        assertTrue(result.validation.phoneFormatValid)
        assertTrue(result.validation.validationErrors.isEmpty())
    }

    @Test
    fun testPersonalDataValidationCPFAlgorithm() {
        val validator = PersonalDataValidator()

        // Valid CPFs
        assertTrue(validator.validateCPF("12345678909"))
        assertTrue(validator.validateCPF("52998224725"))

        // Invalid CPFs
        assertFalse(validator.validateCPF("12345678900"))
        assertFalse(validator.validateCPF("11111111111"))
        assertFalse(validator.validateCPF("00000000000"))
        assertFalse(validator.validateCPF("12345"))
    }

    @Test
    fun testPersonalDataValidationCNPJAlgorithm() {
        val validator = PersonalDataValidator()

        // Valid CNPJs
        assertTrue(validator.validateCNPJ("00000000000191"))
        assertTrue(validator.validateCNPJ("11222333000181"))

        // Invalid CNPJs
        assertFalse(validator.validateCNPJ("00000000000100"))
        assertFalse(validator.validateCNPJ("11111111111111"))
        assertFalse(validator.validateCNPJ("1234"))
    }

    @Test
    fun testPersonalDataValidationFailures() {
        val validator = PersonalDataValidator()
        val input = PersonalDataValidator.Input(
            fullName = "Carlos", // Missing last name
            documentId = "12345678900", // Invalid check digits
            email = "invalid-email-address",
            phoneNumber = "123" // Too short
        )
        val result = validator.validate(input)

        assertFalse(result.validation.isValid)
        assertFalse(result.validation.nameFormatValid)
        assertFalse(result.validation.documentValid)
        assertFalse(result.validation.phoneFormatValid)
        assertEquals(4, result.validation.validationErrors.size)
    }

    // MARK: - Cryptographic Signing Tests

    @Test
    fun testPayloadSignerOutputAndVerification() {
        val secretKey = "enterprise_secret_key_12345"
        val signer = PayloadSigner(secretKey)
        val testPayload = "{\"test\": \"payload_content\"}"
        val nonce = "session_nonce_xyz"

        val securityData = signer.sign(testPayload, nonce)

        assertTrue(securityData.payloadHash.isNotEmpty())
        assertTrue(securityData.signature.isNotEmpty())
        assertEquals(nonce, securityData.nonce)
        assertFalse(securityData.tamperDetected)

        // Verify signature matches
        assertTrue(signer.verify(securityData.payloadHash, nonce, securityData.signature))

        // Tampered hash must fail verification
        assertFalse(signer.verify("tampered_payload_hash", nonce, securityData.signature))
    }

    // MARK: - App Detection Targets Tests

    @Test
    fun testAppDetectionDefaultTargets() {
        val targets = AppDetectionCollector.DEFAULT_TARGETS
        assertTrue(targets.size >= 20)
        assertTrue(targets.any { it.packageName == "com.bet365.app" })
        assertTrue(targets.any { it.packageName == "com.superbet.app" })
        assertTrue(targets.any { it.packageName == "com.sportybet.android" })
        assertTrue(targets.any { it.packageName == "com.betano.app" })
        assertTrue(targets.any { it.packageName == "gr.novibet" })
        assertTrue(targets.any { it.packageName == "com.sportingbet.sportsbook" })
    }

    @Test
    fun testDynamicAppTargetParsingUserRequestedApps() {
        val input = "bet365, Superbet, SportyBet, Betano"
        val targets = AppDetectionCollector.parseTargetsFromInput(input)

        assertTrue(targets.size >= 4)
        assertTrue(targets.any { it.packageName == "com.bet365.app" })
        assertTrue(targets.any { it.packageName == "com.superbet.app" })
        assertTrue(targets.any { it.packageName == "com.sportybet.android" })
        assertTrue(targets.any { it.packageName == "com.betano.app" })
    }

    @Test
    fun testDynamicAppTargetParsingCustomFormats() {
        val input = "com.custom.app, MyBettingApp:com.mybet.pkg, CustomSocial (com.social.app)"
        val targets = AppDetectionCollector.parseTargetsFromInput(input)

        assertEquals(3, targets.size)
        assertTrue(targets.any { it.packageName == "com.custom.app" })
        assertTrue(targets.any { it.packageName == "com.mybet.pkg" && it.name == "MyBettingApp" })
        assertTrue(targets.any { it.packageName == "com.social.app" && it.name == "CustomSocial" })
    }

    // MARK: - JSON Serialization Tests

    @Test
    fun testPayloadJsonSerialization() {
        val payload = SentinelPayload(
            metadata = SentinelMetadata(
                osVersion = "14.0",
                sessionId = "test-session-123",
                requestId = "req-123",
                timestamp = "2026-09-21T23:00:00.000Z",
                captureDurationMs = 150
            ),
            userData = SentinelUserData(
                fullName = "Maria Oliveira",
                documentId = "52998224725",
                email = "maria@example.com",
                phoneNumber = "+5511988887777",
                validation = SentinelUserValidation(
                    isValid = true,
                    nameFormatValid = true,
                    documentValid = true,
                    phoneFormatValid = true,
                    validationErrors = emptyList()
                )
            ),
            deviceData = SentinelDeviceData(
                deviceIdentifier = "test-device-uuid",
                model = "Pixel 8 Pro",
                manufacturer = "Google",
                brand = "google",
                locale = "pt_BR",
                timezone = "America/Sao_Paulo",
                screenResolution = "1344x2992",
                batteryLevel = 0.95f,
                batteryState = "charging",
                isJailbrokenOrRooted = false,
                isEmulator = false,
                telephony = SentinelTelephonyData(
                    carrierName = "Claro BR",
                    mobileCountryCode = "724",
                    mobileNetworkCode = "05",
                    isoCountryCode = "br",
                    networkType = "CELLULAR_5G",
                    isSimReady = true,
                    simOperatorName = "Claro"
                )
            ),
            locationData = SentinelLocationData(
                status = "SUCCESS",
                permissionStatus = "granted_fine",
                coordinates = SentinelCoordinates(
                    latitude = -23.55052,
                    longitude = -46.633308,
                    accuracyMeters = 3.5,
                    altitudeMeters = 760.0
                ),
                timestamp = "2026-09-21T23:00:00.000Z",
                isMockLocation = false
            ),
            installedApps = SentinelInstalledApps(
                scanStrategy = "targeted_manifest_queries",
                totalTargetsScanned = 25,
                totalDetected = 0,
                riskLevel = "CLEAN",
                hasBettingApps = false,
                detectedApps = emptyList()
            ),
            security = SentinelSecurityData(
                payloadHash = "mock_hash",
                signature = "mock_sig",
                nonce = "mock_nonce",
                tamperDetected = false
            )
        )

        val serialized = SentinelSDK.prettyJson.encodeToString(payload)

        assertTrue(serialized.contains("\"sdk_version\": \"1.0.0\""))
        assertTrue(serialized.contains("\"platform\": \"android\""))
        assertTrue(serialized.contains("\"full_name\": \"Maria Oliveira\""))
        assertTrue(serialized.contains("\"carrier_name\": \"Claro BR\""))
    }

    @Test
    fun testPayloadSignerTamperFlag() {
        val signer = PayloadSigner("secret_key_123")
        val securityData = signer.sign("{\"data\":\"val\"}", tamperDetected = true)
        assertTrue(securityData.tamperDetected)
        assertTrue(signer.verify(securityData.payloadHash, securityData.nonce, securityData.signature))
    }
}

