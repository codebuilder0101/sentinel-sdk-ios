package com.sentinel.sdk.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SentinelPayload(
    @SerialName("metadata") val metadata: SentinelMetadata,
    @SerialName("user_data") val userData: SentinelUserData,
    @SerialName("device_data") val deviceData: SentinelDeviceData,
    @SerialName("location_data") val locationData: SentinelLocationData,
    @SerialName("installed_apps") val installedApps: SentinelInstalledApps,
    @SerialName("security") val security: SentinelSecurityData
)

@Serializable
data class SentinelMetadata(
    @SerialName("sdk_version") val sdkVersion: String = "1.0.0",
    @SerialName("platform") val platform: String = "android",
    @SerialName("os_version") val osVersion: String,
    @SerialName("wrapper") val wrapper: String = "native",
    @SerialName("session_id") val sessionId: String,
    @SerialName("request_id") val requestId: String,
    @SerialName("timestamp") val timestamp: String,
    @SerialName("capture_duration_ms") val captureDurationMs: Long
)
