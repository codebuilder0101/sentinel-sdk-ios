import XCTest
@testable import SentinelSDK

final class SentinelSDKTests: XCTestCase {

    // MARK: - Personal Data Validation Tests

    func testPersonalDataValidationSuccess() {
        let validator = PersonalDataValidator()
        let input = PersonalDataValidator.Input(
            fullName: "Carlos Eduardo da Silva",
            documentId: "123.456.789-09", // Valid CPF check digits
            email: "carlos@example.com",
            phoneNumber: "+5511999998888"
        )
        let result = validator.validate(input: input)

        XCTAssertEqual(result.fullName, "Carlos Eduardo da Silva")
        XCTAssertTrue(result.validation.isValid)
        XCTAssertTrue(result.validation.nameFormatValid)
        XCTAssertTrue(result.validation.documentValid)
        XCTAssertTrue(result.validation.phoneFormatValid)
        XCTAssertTrue(result.validation.validationErrors.isEmpty)
    }

    func testDemoAppPresetsValidation() {
        let validator = PersonalDataValidator()

        // 1. Valid Preset used in Demo App
        let validPreset = PersonalDataValidator.Input(
            fullName: "Carlos Eduardo da Silva",
            documentId: "123.456.789-09",
            email: "carlos.silva@example.com",
            phoneNumber: "+5511999998888"
        )
        let validResult = validator.validate(input: validPreset)
        XCTAssertTrue(validResult.validation.isValid)
        XCTAssertTrue(validResult.validation.validationErrors.isEmpty)

        // 2. Invalid Preset used in Demo App
        let invalidPreset = PersonalDataValidator.Input(
            fullName: "Carlos",
            documentId: "111.111.111-11",
            email: "invalid-email-address",
            phoneNumber: "1234"
        )
        let invalidResult = validator.validate(input: invalidPreset)
        XCTAssertFalse(invalidResult.validation.isValid)
        XCTAssertFalse(invalidResult.validation.nameFormatValid)
        XCTAssertFalse(invalidResult.validation.documentValid)
        XCTAssertFalse(invalidResult.validation.phoneFormatValid)
        XCTAssertEqual(invalidResult.validation.validationErrors.count, 4)
    }

    func testPersonalDataValidationCPFAlgorithm() {
        let validator = PersonalDataValidator()

        // Valid CPFs
        XCTAssertTrue(validator.validateCPF("12345678909"))
        XCTAssertTrue(validator.validateCPF("52998224725"))

        // Invalid CPFs
        XCTAssertFalse(validator.validateCPF("12345678900"))
        XCTAssertFalse(validator.validateCPF("11111111111"))
        XCTAssertFalse(validator.validateCPF("00000000000"))
        XCTAssertFalse(validator.validateCPF("12345"))
    }

    func testPersonalDataValidationCNPJAlgorithm() {
        let validator = PersonalDataValidator()

        // Valid CNPJs
        XCTAssertTrue(validator.validateCNPJ("00000000000191"))
        XCTAssertTrue(validator.validateCNPJ("11222333000181"))

        // Invalid CNPJs
        XCTAssertFalse(validator.validateCNPJ("00000000000100"))
        XCTAssertFalse(validator.validateCNPJ("11111111111111"))
        XCTAssertFalse(validator.validateCNPJ("1234"))
    }

    func testPersonalDataValidationFailures() {
        let validator = PersonalDataValidator()
        let input = PersonalDataValidator.Input(
            fullName: "Carlos", // Single token missing last name
            documentId: "12345678900", // Invalid check digits
            email: "invalid-email-address",
            phoneNumber: "123" // Too short
        )
        let result = validator.validate(input: input)

        XCTAssertFalse(result.validation.isValid)
        XCTAssertFalse(result.validation.nameFormatValid)
        XCTAssertFalse(result.validation.documentValid)
        XCTAssertFalse(result.validation.phoneFormatValid)
        XCTAssertEqual(result.validation.validationErrors.count, 4)
    }

    // MARK: - Device Telemetry Tests

    func testDeviceModelMapping() {
        let collector = DeviceDataCollector()
        XCTAssertEqual(collector.mapModelIdentifierToMarketingName("iPhone16,1"), "iPhone 15 Pro")
        XCTAssertEqual(collector.mapModelIdentifierToMarketingName("iPhone16,2"), "iPhone 15 Pro Max")
        XCTAssertEqual(collector.mapModelIdentifierToMarketingName("iPhone15,2"), "iPhone 14 Pro")
        XCTAssertEqual(collector.mapModelIdentifierToMarketingName("iPhone14,2"), "iPhone 13 Pro")
        XCTAssertEqual(collector.mapModelIdentifierToMarketingName("CustomDevice"), "CustomDevice")
    }

    // MARK: - Cryptographic Signing Tests

    func testPayloadSignerOutputAndVerification() {
        let secretKey = "enterprise_secret_key_12345"
        let signer = PayloadSigner(secretKey: secretKey)
        let testData = "test_payload_sample_content".data(using: .utf8)!
        let nonce = "unique_session_nonce_abc"

        let securityData = signer.sign(data: testData, nonce: nonce)

        XCTAssertFalse(securityData.payloadHash.isEmpty)
        XCTAssertFalse(securityData.signature.isEmpty)
        XCTAssertEqual(securityData.nonce, nonce)
        XCTAssertFalse(securityData.tamperDetected)

        // Verify signature matches
        XCTAssertTrue(signer.verify(payloadHash: securityData.payloadHash, nonce: nonce, signature: securityData.signature))

        // Tampered hash must fail verification
        XCTAssertFalse(signer.verify(payloadHash: "tampered_hash", nonce: nonce, signature: securityData.signature))
    }

    // MARK: - App Detection Collector Tests

    func testAppDetectionCollectorDefaults() async {
        let collector = AppDetectionCollector()
        let result = await MainActor.run {
            collector.scan()
        }

        XCTAssertEqual(result.scanStrategy, "targeted_scheme_queries")
        XCTAssertGreaterThanOrEqual(result.totalTargetsScanned, 20)
        XCTAssertGreaterThan(result.unresolvedSchemesCount, 0)
    }

    func testAppDetectionCollectorCustomTargets() async {
        let collector = AppDetectionCollector()
        let customTargets = [
            AppDetectionCollector.TargetApp(id: "custom_bet", name: "Custom Bet", scheme: "custombet"),
            AppDetectionCollector.TargetApp(id: "no_scheme_app", name: "No Scheme", scheme: nil)
        ]

        let result = await MainActor.run {
            collector.scan(targets: customTargets)
        }

        XCTAssertEqual(result.totalTargetsScanned, 2)
        XCTAssertEqual(result.unresolvedSchemesCount, 1)
    }

    // MARK: - End-to-End SDK Facade Tests

    func testSDKCaptureJSONOutput() async throws {
        let sdk = SentinelSDK.shared
        sdk.initialize(apiKey: "test_enterprise_api_key_12345", environment: "sandbox")

        let config = SentinelSDK.CaptureConfiguration(
            userData: PersonalDataValidator.Input(
                fullName: "Carlos Eduardo da Silva",
                documentId: "123.456.789-09",
                email: "carlos.silva@example.com",
                phoneNumber: "+5511999998888"
            ),
            locationTimeoutSeconds: 1.0,
            wrapper: "native_ios_demo"
        )

        let jsonString = try await sdk.captureJSON(configuration: config)

        XCTAssertFalse(jsonString.isEmpty)
        XCTAssertTrue(jsonString.contains("\"sdk_version\" : \"1.0.0\""))
        XCTAssertTrue(jsonString.contains("\"full_name\" : \"Carlos Eduardo da Silva\""))
        XCTAssertTrue(jsonString.contains("\"wrapper\" : \"native_ios_demo\""))
        XCTAssertTrue(jsonString.contains("\"payload_hash\""))
        XCTAssertTrue(jsonString.contains("\"signature\""))
    }
}
