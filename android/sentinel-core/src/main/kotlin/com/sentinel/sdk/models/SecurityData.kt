package com.sentinel.sdk.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SentinelSecurityData(
    @SerialName("payload_hash") val payloadHash: String,
    @SerialName("signature") val signature: String,
    @SerialName("nonce") val nonce: String,
    @SerialName("tamper_detected") val tamperDetected: Boolean = false
)
