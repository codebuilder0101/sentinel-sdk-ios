package com.sentinel.sdk.collectors

import com.sentinel.sdk.models.SentinelUserData
import com.sentinel.sdk.models.SentinelUserValidation
import java.util.regex.Pattern

class PersonalDataValidator {

    data class Input(
        val fullName: String,
        val documentId: String? = null,
        val email: String? = null,
        val phoneNumber: String? = null
    )

    private val emailPattern = Pattern.compile(
        "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
    )

    fun validate(input: Input): SentinelUserData {
        val errors = mutableListOf<String>()

        // 1. Full name validation: at least 2 tokens, minimum 3 characters
        val trimmedName = input.fullName.trim()
        val nameTokens = trimmedName.split("\\s+".toRegex()).filter { it.isNotBlank() }
        val isNameValid = nameTokens.size >= 2 && trimmedName.length >= 3

        if (!isNameValid) {
            errors.add("Full name must contain at least a first and last name (minimum 3 characters).")
        }

        // 2. Document validation (CPF 11 digits, CNPJ 14 digits, or generic alphanumeric)
        var isDocValid = true
        input.documentId?.let { doc ->
            val digitsOnly = doc.filter { it.isDigit() }
            if (digitsOnly.length == 11) {
                isDocValid = validateCPF(digitsOnly)
                if (!isDocValid) {
                    errors.add("Invalid CPF document check digits.")
                }
            } else if (digitsOnly.length == 14) {
                isDocValid = validateCNPJ(digitsOnly)
                if (!isDocValid) {
                    errors.add("Invalid CNPJ document check digits.")
                }
            } else if (digitsOnly.length < 5 && doc.length < 5) {
                isDocValid = false
                errors.add("Document ID must contain at least 5 characters.")
            }
        }

        // 3. Phone number validation (8 to 15 digits)
        var isPhoneValid = true
        input.phoneNumber?.let { phone ->
            val digitsOnly = phone.filter { it.isDigit() }
            isPhoneValid = digitsOnly.length in 8..15
            if (!isPhoneValid) {
                errors.add("Phone number must contain between 8 and 15 digits.")
            }
        }

        // 4. Email validation
        input.email?.let { email ->
            if (email.isNotBlank() && !emailPattern.matcher(email).matches()) {
                errors.add("Invalid email address format.")
            }
        }

        val isValid = isNameValid && isDocValid && isPhoneValid && errors.isEmpty()

        val validation = SentinelUserValidation(
            isValid = isValid,
            nameFormatValid = isNameValid,
            documentValid = isDocValid,
            phoneFormatValid = isPhoneValid,
            validationErrors = errors
        )

        return SentinelUserData(
            fullName = trimmedName,
            documentId = input.documentId,
            email = input.email,
            phoneNumber = input.phoneNumber,
            validation = validation
        )
    }

    /// Validates Brazilian CPF checksum digits (11 digits)
    fun validateCPF(cpf: String): Boolean {
        val digitsOnly = cpf.filter { it.isDigit() }
        if (digitsOnly.length != 11 || digitsOnly.all { it == digitsOnly[0] }) return false
        val numbers = digitsOnly.map { it.toString().toInt() }

        // First verification digit
        val sum1 = (0..8).sumOf { numbers[it] * (10 - it) }
        val rem1 = sum1 % 11
        val v1 = if (rem1 < 2) 0 else 11 - rem1
        if (numbers[9] != v1) return false

        // Second verification digit
        val sum2 = (0..9).sumOf { numbers[it] * (11 - it) }
        val rem2 = sum2 % 11
        val v2 = if (rem2 < 2) 0 else 11 - rem2
        return numbers[10] == v2
    }

    /// Validates Brazilian CNPJ checksum digits (14 digits)
    fun validateCNPJ(cnpj: String): Boolean {
        val digitsOnly = cnpj.filter { it.isDigit() }
        if (digitsOnly.length != 14 || digitsOnly.all { it == digitsOnly[0] }) return false
        val numbers = digitsOnly.map { it.toString().toInt() }

        val weights1 = intArrayOf(5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2)
        val sum1 = (0..11).sumOf { numbers[it] * weights1[it] }
        val rem1 = sum1 % 11
        val v1 = if (rem1 < 2) 0 else 11 - rem1
        if (numbers[12] != v1) return false

        val weights2 = intArrayOf(6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2)
        val sum2 = (0..12).sumOf { numbers[it] * weights2[it] }
        val rem2 = sum2 % 11
        val v2 = if (rem2 < 2) 0 else 11 - rem2
        return numbers[13] == v2
    }
}
