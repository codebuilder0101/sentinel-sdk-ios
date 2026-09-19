package com.sentinel.sdk.collectors

import com.sentinel.sdk.models.SentinelUserData
import com.sentinel.sdk.models.SentinelUserValidation

class PersonalDataValidator {

    data class Input(
        val fullName: String,
        val documentId: String? = null,
        val email: String? = null,
        val phoneNumber: String? = null
    )

    fun validate(input: Input): SentinelUserData {
        val errors = mutableListOf<String>()

        val trimmedName = input.fullName.trim()
        val nameTokens = trimmedName.split("\\s+".toRegex()).filter { it.isNotBlank() }
        val isNameValid = nameTokens.size >= 2 && trimmedName.length >= 3

        if (!isNameValid) {
            errors.add("Full name must contain at least a first and last name.")
        }

        var isDocValid = true
        input.documentId?.let { doc ->
            val digitsOnly = doc.filter { it.isDigit() }
            if (digitsOnly.length == 11) {
                isDocValid = validateCPF(digitsOnly)
                if (!isDocValid) {
                    errors.add("Invalid CPF document check digits.")
                }
            } else if (digitsOnly.length < 5) {
                isDocValid = false
                errors.add("Document ID must be at least 5 alphanumeric characters.")
            }
        }

        var isPhoneValid = true
        input.phoneNumber?.let { phone ->
            val digitsOnly = phone.filter { it.isDigit() }
            isPhoneValid = digitsOnly.length in 8..15
            if (!isPhoneValid) {
                errors.add("Phone number must contain between 8 and 15 digits.")
            }
        }

        input.email?.let { email ->
            if (email.isNotBlank() && !android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
                errors.add("Invalid email format.")
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

    private fun validateCPF(cpf: String): Boolean {
        if (cpf.length != 11 || cpf.all { it == cpf[0] }) return false
        val numbers = cpf.map { it.toString().toInt() }

        val d1 = (0..8).sumOf { numbers[it] * (10 - it) } % 11
        val v1 = if (d1 < 2) 0 else 11 - d1
        if (numbers[9] != v1) return false

        val d2 = (0..9).sumOf { numbers[it] * (11 - it) } % 11
        val v2 = if (d2 < 2) 0 else 11 - d2
        return numbers[10] == v2
    }
}
