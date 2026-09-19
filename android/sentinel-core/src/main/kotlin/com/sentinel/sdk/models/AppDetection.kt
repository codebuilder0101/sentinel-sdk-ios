package com.sentinel.sdk.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SentinelInstalledApps(
    @SerialName("scan_strategy") val scanStrategy: String = "targeted_manifest_queries",
    @SerialName("total_targets_scanned") val totalTargetsScanned: Int,
    @SerialName("total_detected") val totalDetected: Int,
    @SerialName("risk_level") val riskLevel: String,
    @SerialName("has_betting_apps") val hasBettingApps: Boolean,
    @SerialName("detected_apps") val detectedApps: List<SentinelDetectedApp>,
    @SerialName("unresolved_schemes_count") val unresolvedSchemesCount: Int = 0
)

@Serializable
data class SentinelDetectedApp(
    @SerialName("target_id") val targetId: String,
    @SerialName("app_name") val appName: String,
    @SerialName("category") val category: String = "gambling_betting",
    @SerialName("detection_identifier") val detectionIdentifier: String,
    @SerialName("detection_method") val detectionMethod: String = "package_manager_query",
    @SerialName("is_detected") val isDetected: Boolean
)
