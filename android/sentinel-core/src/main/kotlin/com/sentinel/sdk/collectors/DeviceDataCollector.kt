package com.sentinel.sdk.collectors

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.provider.Settings
import android.telephony.TelephonyManager
import com.sentinel.sdk.models.SentinelDeviceData
import com.sentinel.sdk.models.SentinelTelephonyData
import java.io.File
import java.util.Locale
import java.util.TimeZone

class DeviceDataCollector(private val context: Context) {

    fun collect(): SentinelDeviceData {
        val deviceId = getDeviceIdentifier()
        val model = Build.MODEL
        val manufacturer = Build.MANUFACTURER
        val brand = Build.BRAND
        val locale = Locale.getDefault().toString()
        val timezone = TimeZone.getDefault().id

        val displayMetrics = context.resources.displayMetrics
        val screenResolution = "${displayMetrics.widthPixels}x${displayMetrics.heightPixels}"

        val (batteryLevel, batteryState) = getBatteryInfo()
        val isRooted = checkRootHeuristics()
        val isEmulator = checkEmulator()
        val telephony = collectTelephony()

        return SentinelDeviceData(
            deviceIdentifier = deviceId,
            model = model,
            manufacturer = manufacturer,
            brand = brand,
            locale = locale,
            timezone = timezone,
            screenResolution = screenResolution,
            batteryLevel = batteryLevel,
            batteryState = batteryState,
            isJailbrokenOrRooted = isRooted,
            isEmulator = isEmulator,
            telephony = telephony
        )
    }

    private fun getDeviceIdentifier(): String {
        return Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
            ?: "unknown_android_device"
    }

    private fun getBatteryInfo(): Pair<Float, String> {
        val batteryIntent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val batteryPct = if (level >= 0 && scale > 0) level / scale.toFloat() else 1.0f

        val status = batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val state = when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
            BatteryManager.BATTERY_STATUS_FULL -> "full"
            BatteryManager.BATTERY_STATUS_DISCHARGING, BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "unplugged"
            else -> "unknown"
        }

        return Pair(batteryPct, state)
    }

    private fun collectTelephony(): SentinelTelephonyData {
        val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        val carrierName = tm?.networkOperatorName?.takeIf { it.isNotBlank() } ?: "Unknown"
        val operator = tm?.networkOperator ?: "00000"

        val mcc = if (operator.length >= 3) operator.substring(0, 3) else "000"
        val mnc = if (operator.length > 3) operator.substring(3) else "00"
        val isoCountry = tm?.networkCountryIso ?: "xx"
        val isSimReady = tm?.simState == TelephonyManager.SIM_STATE_READY

        return SentinelTelephonyData(
            carrierName = carrierName,
            mobileCountryCode = mcc,
            mobileNetworkCode = mnc,
            isoCountryCode = isoCountry,
            networkType = "CELLULAR_5G",
            isSimReady = isSimReady,
            simOperatorName = tm?.simOperatorName?.takeIf { it.isNotBlank() } ?: carrierName
        )
    }

    private fun checkRootHeuristics(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su"
        )
        for (path in paths) {
            if (File(path).exists()) return true
        }
        val buildTags = Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }

    private fun checkEmulator(): Boolean {
        return (Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86")
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")
                || "google_sdk" == Build.PRODUCT)
    }
}
