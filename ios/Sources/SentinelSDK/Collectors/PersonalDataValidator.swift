import Foundation

/// Validates personal identification data supplied to the SDK.
public final class PersonalDataValidator {

    public init() {}

    public struct Input {
        public let fullName: String
        public let documentId: String?
        public let email: String?
        public let phoneNumber: String?

        public init(
            fullName: String,
            documentId: String? = nil,
            email: String? = nil,
            phoneNumber: String? = nil
        ) {
            self.fullName = fullName
            self.documentId = documentId
            self.email = email
            self.phoneNumber = phoneNumber
        }
    }

    public func validate(input: Input) -> SentinelUserData {
        var errors: [String] = []

        // 1. Full name validation: at least 2 tokens, minimum 3 characters
        let trimmedName = input.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameComponents = trimmedName.split(separator: " ").filter { !$0.isEmpty }
        let isNameFormatValid = nameComponents.count >= 2 && trimmedName.count >= 3

        if !isNameFormatValid {
            errors.append("Full name must contain at least a first and last name (minimum 3 characters).")
        }

        // 2. Document validation (e.g., CPF 11-digits, CNPJ 14-digits, or generic ID)
        var isDocumentValid = true
        if let doc = input.documentId, !doc.isEmpty {
            let digitsOnly = doc.filter { $0.isNumber }
            if digitsOnly.count == 11 {
                isDocumentValid = validateCPF(digitsOnly)
                if !isDocumentValid {
                    errors.append("Invalid CPF document check digits.")
                }
            } else if digitsOnly.count == 14 {
                isDocumentValid = validateCNPJ(digitsOnly)
                if !isDocumentValid {
                    errors.append("Invalid CNPJ document check digits.")
                }
            } else if digitsOnly.count < 5 && doc.count < 5 {
                isDocumentValid = false
                errors.append("Document ID must contain at least 5 characters.")
            }
        }

        // 3. Phone number validation (E.164 or national format)
        var isPhoneValid = true
        if let phone = input.phoneNumber, !phone.isEmpty {
            let digitsOnly = phone.filter { $0.isNumber }
            isPhoneValid = digitsOnly.count >= 8 && digitsOnly.count <= 15
            if !isPhoneValid {
                errors.append("Phone number must contain between 8 and 15 digits.")
            }
        }

        // 4. Email validation (RFC 5322 compatible regex)
        if let email = input.email, !email.isEmpty {
            let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: email) {
                errors.append("Invalid email address format.")
            }
        }

        let isValid = isNameFormatValid && isDocumentValid && isPhoneValid && errors.isEmpty

        let validation = SentinelUserValidation(
            isValid: isValid,
            nameFormatValid: isNameFormatValid,
            documentValid: isDocumentValid,
            phoneFormatValid: isPhoneValid,
            validationErrors: errors
        )

        return SentinelUserData(
            fullName: trimmedName,
            documentId: input.documentId,
            email: input.email,
            phoneNumber: input.phoneNumber,
            validation: validation
        )
    }

    /// Validates Brazilian CPF checksum digits (11 digits)
    public func validateCPF(_ cpf: String) -> Bool {
        let digits = cpf.compactMap { Int(String($0)) }
        guard digits.count == 11 else { return false }
        if Set(digits).count == 1 { return false } // Reject 111.111.111-11, etc.

        // First verification digit
        let sum1 = (0..<9).reduce(0) { $0 + digits[$1] * (10 - $1) }
        let rem1 = sum1 % 11
        let v1 = rem1 < 2 ? 0 : 11 - rem1
        if digits[9] != v1 { return false }

        // Second verification digit
        let sum2 = (0..<10).reduce(0) { $0 + digits[$1] * (11 - $1) }
        let rem2 = sum2 % 11
        let v2 = rem2 < 2 ? 0 : 11 - rem2
        return digits[10] == v2
    }

    /// Validates Brazilian CNPJ checksum digits (14 digits)
    public func validateCNPJ(_ cnpj: String) -> Bool {
        let digits = cnpj.compactMap { Int(String($0)) }
        guard digits.count == 14 else { return false }
        if Set(digits).count == 1 { return false }

        let weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
        let sum1 = (0..<12).reduce(0) { $0 + digits[$1] * weights1[$1] }
        let rem1 = sum1 % 11
        let v1 = rem1 < 2 ? 0 : 11 - rem1
        if digits[12] != v1 { return false }

        let weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
        let sum2 = (0..<13).reduce(0) { $0 + digits[$1] * weights2[$1] }
        let rem2 = sum2 % 11
        let v2 = rem2 < 2 ? 0 : 11 - rem2
        return digits[13] == v2
    }
}
