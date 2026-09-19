package com.sentinel.sdk.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SentinelUserData(
    @SerialName("full_name") val fullName: String,
    @SerialName("document_id") val documentId: String? = null,
    @SerialName("email") val email: String? = null,
    @SerialName("phone_number") val phoneNumber: String? = null,
    @SerialName("validation") val validation: SentinelUserValidation
)

@Serializable
data class SentinelUserValidation(
    @SerialName("is_valid") val isValid: Boolean,
    @SerialName("name_format_valid") val nameFormatValid: Boolean,
    @SerialName("document_valid") val documentValid: Boolean,
    @SerialName("phone_format_valid") val phoneFormatValid: Boolean,
    @SerialName("validation_errors") val validationErrors: List<String>
)
