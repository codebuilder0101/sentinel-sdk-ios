import Foundation

/// Validates personal identification data supplied to the SDK.
public final class PersonalDataValidator {

    public init() {}

    public struct Input {
        public let fullName: String
        public let documentId: String?
        public let email: String?
        public let phoneNumber: String?

        public init(fullName: String, documentId: String? = nil, email: String? = nil, phoneNumber: String? = nil) {
            self.fullName = fullName
            self.documentId = documentId
            self.email = email
            self.phoneNumber = phoneNumber
        }
    }

    public func validate(input: Input) -> SentinelUserData {
        var errors: [String] = []

        // 1. Full name validation: at least 2 tokens, letters only (with spaces, apostrophes, hyphens)
        let trimmedName = input.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameComponents = trimmedName.split(separator: " ").filter { !$0.isEmpty }
        let isNameFormatValid = nameComponents.count >= 2 && trimmedName.count >= 3

        if !isNameFormatValid {
            errors.append("Full name must contain at least a first and last name.")
        }

        // 2. Document validation (e.g., CPF or generic ID)
        var isDocumentValid = true
        if let doc = input.documentId, !doc.isEmpty {
            let digitsOnly = doc.filter { $0.isNumber }
            if digitsOnly.count == 11 {
                isDocumentValid = validateCPF(digitsOnly)
                if !isDocumentValid {
                    errors.append("Invalid CPF document check digits.")
                }
            } else if digitsOnly.count < 5 {
                isDocumentValid = false
                errors.append("Document ID must be at least 5 alphanumeric characters.")
            }
        }

        // 3. Phone number validation (E.164 or national)
        var isPhoneValid = true
        if let phone = input.phoneNumber, !phone.isEmpty {
            let digitsOnly = phone.filter { $0.isNumber }
            isPhoneValid = digitsOnly.count >= 8 && digitsOnly.count <= 15
            if !isPhoneValid {
                errors.append("Phone number must contain between 8 and 15 digits.")
            }
        }

        // 4. Email validation (if provided)
        if let email = input.email, !email.isEmpty {
            let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: email) {
                errors.append("Invalid email format.")
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

    /// Validates Brazilian CPF checksum digits (if an 11-digit document is supplied)
    private func validateCPF(_ cpf: String) -> Bool {
        let numbers = cpf.compactMap { Int(String($0)) }
        guard numbers.count == 11 else { return false }
        if Set(numbers).count == 1 { return false } // Disallow 111.111.111-11

        let d1 = (0..<9).reduce(0) { $0 + numbers[$1] * (10 - $1) } % 11
        let v1 = d1 < 2 ? 0 : 11 - d1
        if numbers[9] != v1 { return false }

        let d2 = (0..<10).reduce(0) { $0 + numbers[$1] * (11 - $1) } % 11
        let v2 = d2 < 2 ? 0 : 11 - d2
        return numbers[10] == v2
    }
}
