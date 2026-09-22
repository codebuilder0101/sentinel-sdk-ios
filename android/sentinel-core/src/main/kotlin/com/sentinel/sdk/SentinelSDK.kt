package com.sentinel.sdk

import android.content.Context
import android.os.Build
import com.sentinel.sdk.collectors.AppDetectionCollector
import com.sentinel.sdk.collectors.DeviceDataCollector
import com.sentinel.sdk.collectors.LocationCollector
import com.sentinel.sdk.collectors.PersonalDataValidator
import com.sentinel.sdk.models.SentinelDeviceData
import com.sentinel.sdk.models.SentinelInstalledApps
import com.sentinel.sdk.models.SentinelLocationData
import com.sentinel.sdk.models.SentinelMetadata
import com.sentinel.sdk.models.SentinelPayload
import com.sentinel.sdk.models.SentinelUserData
import com.sentinel.sdk.security.PayloadSigner
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID

class SentinelSDK private constructor(private val context: Context) {

    companion object {
        const val VERSION = "1.0.0"

        @Volatile
        private var INSTANCE: SentinelSDK? = null

        val compactJson = Json {
            encodeDefaults = true
            ignoreUnknownKeys = true
            prettyPrint = false
        }

        val prettyJson = Json {
            encodeDefaults = true
            ignoreUnknownKeys = true
            prettyPrint = true
        }

        fun formatJson(payload: SentinelPayload, prettyPrint: Boolean = true): String {
            val serializer = if (prettyPrint) prettyJson else compactJson
            return serializer.encodeToString(payload)
        }

        fun initialize(context: Context, apiKey: String, environment: String = "production"): SentinelSDK {
            return INSTANCE?.apply {
                this.apiKey = apiKey
                this.environment = environment
            } ?: synchronized(this) {
                INSTANCE ?: SentinelSDK(context.applicationContext ?: context).also {
                    it.apiKey = apiKey
                    it.environment = environment
                    it.isInitialized = true
                    INSTANCE = it
                }
            }
        }

        fun getInstance(): SentinelSDK {
            return INSTANCE ?: throw IllegalStateException("SentinelSDK must be initialized first via SentinelSDK.initialize(context, apiKey).")
        }

        fun resetForTesting() {
            synchronized(this) {
                INSTANCE = null
            }
        }
    }

    private var apiKey: String? = null
    private var environment: String = "production"
    private var isInitialized: Boolean = false

    private val personalDataValidator = PersonalDataValidator()
    private val deviceDataCollector = DeviceDataCollector(context)
    private val locationCollector = LocationCollector(context)
    private val appDetectionCollector = AppDetectionCollector(context)

    data class CaptureOptions(
        val userData: PersonalDataValidator.Input,
        val locationTimeoutMs: Long = 5000L,
        val wrapper: String = "native",
        val customTargets: List<AppDetectionCollector.TargetApp>? = null
    )

    suspend fun capture(options: CaptureOptions): SentinelPayload = coroutineScope {
        val startTime = System.currentTimeMillis()

        // 1. Personal Data Validation (CPU-bound)
        val userData = personalDataValidator.validate(options.userData)

        // 2. Parallel Telemetry Collectors
        val deviceDataDeferred = async(Dispatchers.IO) { deviceDataCollector.collect() }
        val locationDataDeferred = async(Dispatchers.IO) {
            locationCollector.collectLocation(timeoutMs = options.locationTimeoutMs)
        }
        val targets = options.customTargets ?: AppDetectionCollector.DEFAULT_TARGETS
        val installedAppsDeferred = async(Dispatchers.IO) {
            appDetectionCollector.scan(targets)
        }

        val deviceData = deviceDataDeferred.await()
        val locationData = locationDataDeferred.await()
        val installedApps = installedAppsDeferred.await()

        val duration = maxOf(1L, System.currentTimeMillis() - startTime)
        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }

        val metadata = SentinelMetadata(
            sdkVersion = VERSION,
            platform = "android",
            osVersion = Build.VERSION.RELEASE ?: "unknown",
            wrapper = options.wrapper,
            sessionId = UUID.randomUUID().toString(),
            requestId = "req_" + UUID.randomUUID().toString().replace("-", "").lowercase(),
            timestamp = sdf.format(Date(startTime)),
            captureDurationMs = duration
        )

        // Security signature (Canonical compact JSON)
        val unsignedPayload = PreSecurityPayload(
            metadata = metadata,
            userData = userData,
            deviceData = deviceData,
            locationData = locationData,
            installedApps = installedApps
        )

        val isTampered = deviceData.isJailbrokenOrRooted || locationData.isMockLocation
        val signer = PayloadSigner(apiKey)
        val unsignedCanonicalJson = compactJson.encodeToString(unsignedPayload)
        val securityData = signer.sign(unsignedCanonicalJson, tamperDetected = isTampered)

        SentinelPayload(
            metadata = metadata,
            userData = userData,
            deviceData = deviceData,
            locationData = locationData,
            installedApps = installedApps,
            security = securityData
        )
    }

    suspend fun captureJson(options: CaptureOptions, prettyPrint: Boolean = true): String {
        val payload = capture(options)
        val serializer = if (prettyPrint) prettyJson else compactJson
        return serializer.encodeToString(payload)
    }
}

@Serializable
private data class PreSecurityPayload(
    @SerialName("metadata") val metadata: SentinelMetadata,
    @SerialName("user_data") val userData: SentinelUserData,
    @SerialName("device_data") val deviceData: SentinelDeviceData,
    @SerialName("location_data") val locationData: SentinelLocationData,
    @SerialName("installed_apps") val installedApps: SentinelInstalledApps
)

