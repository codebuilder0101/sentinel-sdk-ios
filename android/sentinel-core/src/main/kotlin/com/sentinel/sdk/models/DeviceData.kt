package com.sentinel.sdk.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SentinelDeviceData(
    @SerialName("device_identifier") val deviceIdentifier: String,
    @SerialName("model") val model: String,
    @SerialName("manufacturer") val manufacturer: String,
    @SerialName("brand") val brand: String,
    @SerialName("locale") val locale: String,
    @SerialName("timezone") val timezone: String,
    @SerialName("screen_resolution") val screenResolution: String,
    @SerialName("battery_level") val batteryLevel: Float,
    @SerialName("battery_state") val batteryState: String,
    @SerialName("is_jailbroken_or_rooted") val isJailbrokenOrRooted: Boolean,
    @SerialName("is_emulator") val isEmulator: Boolean,
    @SerialName("telephony") val telephony: SentinelTelephonyData
)

@Serializable
data class SentinelTelephonyData(
    @SerialName("carrier_name") val carrierName: String,
    @SerialName("mobile_country_code") val mobileCountryCode: String,
    @SerialName("mobile_network_code") val mobileNetworkCode: String,
    @SerialName("iso_country_code") val isoCountryCode: String,
    @SerialName("network_type") val networkType: String,
    @SerialName("is_sim_ready") val isSimReady: Boolean,
    @SerialName("sim_operator_name") val simOperatorName: String? = null
)
