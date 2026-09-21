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
import kotlinx.coroutines.withContext
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

        fun initialize(context: Context, apiKey: String, environment: String = "production"): SentinelSDK {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: SentinelSDK(context.applicationContext).also {
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
    }

    private var apiKey: String? = null
    private var environment: String = "production"
    private var isInitialized: Boolean = false

    private val personalDataValidator = PersonalDataValidator()
    private val deviceDataCollector = DeviceDataCollector(context)
    private val locationCollector = LocationCollector(context)
    private val appDetectionCollector = AppDetectionCollector(context)

    private val json = Json {
        prettyPrint = true
        encodeDefaults = true
        ignoreUnknownKeys = true
    }

    data class CaptureOptions(
        val userData: PersonalDataValidator.Input,
        val locationTimeoutMs: Long = 5000L,
        val wrapper: String = "native",
        val customTargets: List<AppDetectionCollector.TargetApp>? = null
    )

    suspend fun capture(options: CaptureOptions): SentinelPayload = withContext(Dispatchers.IO) {
        val startTime = System.currentTimeMillis()

        // 1. Personal Data Validation
        val userData = personalDataValidator.validate(options.userData)

        // 2. Device Data Collection
        val deviceData = deviceDataCollector.collect()

        // 3. Location Capture
        val locationData = locationCollector.collectLocation(timeoutMs = options.locationTimeoutMs)

        // 4. Targeted App Screening
        val targets = options.customTargets ?: AppDetectionCollector.DEFAULT_TARGETS
        val installedApps = appDetectionCollector.scan(targets)

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

        // Security signature
        val unsignedPayload = PreSecurityPayload(
            metadata = metadata,
            userData = userData,
            deviceData = deviceData,
            locationData = locationData,
            installedApps = installedApps
        )

        val signer = PayloadSigner(apiKey)
        val unsignedJson = json.encodeToString(unsignedPayload)
        val securityData = signer.sign(unsignedJson)

        SentinelPayload(
            metadata = metadata,
            userData = userData,
            deviceData = deviceData,
            locationData = locationData,
            installedApps = installedApps,
            security = securityData
        )
    }

    suspend fun captureJson(options: CaptureOptions): String {
        val payload = capture(options)
        return json.encodeToString(payload)
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
