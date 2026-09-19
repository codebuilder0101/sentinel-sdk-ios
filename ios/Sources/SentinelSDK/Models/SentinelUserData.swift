import Foundation

/// User personal data input and validation results.
public struct SentinelUserData: Codable {
    public let fullName: String
    public let documentId: String?
    public let email: String?
    public let phoneNumber: String?
    public let validation: SentinelUserValidation

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case documentId = "document_id"
        case email
        case phoneNumber = "phone_number"
        case validation
    }

    public init(
        fullName: String,
        documentId: String? = nil,
        email: String? = nil,
        phoneNumber: String? = nil,
        validation: SentinelUserValidation
    ) {
        self.fullName = fullName
        self.documentId = documentId
        self.email = email
        self.phoneNumber = phoneNumber
        self.validation = validation
    }
}

public struct SentinelUserValidation: Codable {
    public let isValid: Bool
    public let nameFormatValid: Bool
    public let documentValid: Bool
    public let phoneFormatValid: Bool
    public let validationErrors: [String]

    enum CodingKeys: String, CodingKey {
        case isValid = "is_valid"
        case nameFormatValid = "name_format_valid"
        case documentValid = "document_valid"
        case phoneFormatValid = "phone_format_valid"
        case validationErrors = "validation_errors"
    }

    public init(
        isValid: Bool,
        nameFormatValid: Bool,
        documentValid: Bool,
        phoneFormatValid: Bool,
        validationErrors: [String]
    ) {
        self.isValid = isValid
        self.nameFormatValid = nameFormatValid
        self.documentValid = documentValid
        self.phoneFormatValid = phoneFormatValid
        self.validationErrors = validationErrors
    }
}
