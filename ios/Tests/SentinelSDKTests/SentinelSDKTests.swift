import XCTest
@testable import SentinelSDK

final class SentinelSDKTests: XCTestCase {

    func testPersonalDataValidationSuccess() {
        let validator = PersonalDataValidator()
        let input = PersonalDataValidator.Input(
            fullName: "Carlos Eduardo da Silva",
            documentId: "123.456.789-00",
            email: "carlos@example.com",
            phoneNumber: "+5511999998888"
        )
        let result = validator.validate(input: input)

        XCTAssertEqual(result.fullName, "Carlos Eduardo da Silva")
        XCTAssertTrue(result.validation.nameFormatValid)
        XCTAssertTrue(result.validation.phoneFormatValid)
    }

    func testPersonalDataValidationFailure() {
        let validator = PersonalDataValidator()
        let input = PersonalDataValidator.Input(
            fullName: "Carlos", // Missing last name
            documentId: "12",
            email: "invalid-email",
            phoneNumber: "123"
        )
        let result = validator.validate(input: input)

        XCTAssertFalse(result.validation.isValid)
        XCTAssertFalse(result.validation.nameFormatValid)
        XCTAssertFalse(result.validation.phoneFormatValid)
        XCTAssertFalse(result.validation.validationErrors.isEmpty)
    }

    func testPayloadSignerOutput() {
        let signer = PayloadSigner(secretKey: "test_secret_key")
        let testData = "test_payload_data".data(using: .utf8)!
        let securityData = signer.sign(data: testData, nonce: "test_nonce_123")

        XCTAssertFalse(securityData.payloadHash.isEmpty)
        XCTAssertFalse(securityData.signature.isEmpty)
        XCTAssertEqual(securityData.nonce, "test_nonce_123")
    }

    func testAppDetectionCollectorDefaults() async {
        let collector = AppDetectionCollector()
        let result = await MainActor.run {
            collector.scan()
        }

        XCTAssertEqual(result.scanStrategy, "targeted_scheme_queries")
        XCTAssertGreaterThan(result.totalTargetsScanned, 0)
    }
}
