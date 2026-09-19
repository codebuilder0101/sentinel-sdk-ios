package com.sentinel.sdk.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SentinelLocationData(
    @SerialName("status") val status: String,
    @SerialName("permission_status") val permissionStatus: String,
    @SerialName("coordinates") val coordinates: SentinelCoordinates,
    @SerialName("timestamp") val timestamp: String,
    @SerialName("is_mock_location") val isMockLocation: Boolean
)

@Serializable
data class SentinelCoordinates(
    @SerialName("latitude") val latitude: Double,
    @SerialName("longitude") val longitude: Double,
    @SerialName("accuracy_meters") val accuracyMeters: Double,
    @SerialName("altitude_meters") val altitudeMeters: Double? = null,
    @SerialName("altitude_accuracy_meters") val altitudeAccuracyMeters: Double? = null,
    @SerialName("heading_degrees") val headingDegrees: Double? = null,
    @SerialName("speed_mps") val speedMps: Double? = null
)
