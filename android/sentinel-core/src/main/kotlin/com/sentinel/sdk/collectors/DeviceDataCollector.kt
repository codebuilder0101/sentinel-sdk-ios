package com.sentinel.sdk.collectors

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.provider.Settings
import android.telephony.TelephonyManager
import com.sentinel.sdk.models.SentinelDeviceData
import com.sentinel.sdk.models.SentinelTelephonyData
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.util.Locale
import java.util.TimeZone

class DeviceDataCollector(private val context: Context) {

    fun collect(): SentinelDeviceData {
        val deviceId = getDeviceIdentifier()
        val model = Build.MODEL ?: "Unknown Android Device"
        val manufacturer = Build.MANUFACTURER ?: "Android"
        val brand = Build.BRAND ?: "Android"
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
        return try {
            Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
                ?: "00000000-0000-0000-0000-000000000000"
        } catch (_: Exception) {
            "00000000-0000-0000-0000-000000000000"
        }
    }

    private fun getBatteryInfo(): Pair<Float, String> {
        return try {
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
            Pair(batteryPct, state)
        } catch (_: Exception) {
            Pair(1.0f, "unknown")
        }
    }

    private fun collectTelephony(): SentinelTelephonyData {
        val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        val carrierName = tm?.networkOperatorName?.takeIf { it.isNotBlank() } ?: "Unknown"
        val operator = tm?.networkOperator ?: "00000"

        val mcc = if (operator.length >= 3) operator.substring(0, 3) else "000"
        val mnc = if (operator.length > 3) operator.substring(3) else "00"
        val isoCountry = tm?.networkCountryIso?.takeIf { it.isNotBlank() } ?: "xx"
        val isSimReady = tm?.simState == TelephonyManager.SIM_STATE_READY

        val networkType = determineNetworkType()

        return SentinelTelephonyData(
            carrierName = carrierName,
            mobileCountryCode = mcc,
            mobileNetworkCode = mnc,
            isoCountryCode = isoCountry,
            networkType = networkType,
            isSimReady = isSimReady,
            simOperatorName = tm?.simOperatorName?.takeIf { it.isNotBlank() } ?: carrierName
        )
    }

    private fun determineNetworkType(): String {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            ?: return "NONE"

        val activeNetwork = cm.activeNetwork ?: return "NONE"
        val caps = cm.getNetworkCapabilities(activeNetwork) ?: return "NONE"

        return when {
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "WIFI"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "CELLULAR"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ETHERNET"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "VPN"
            else -> "UNKNOWN"
        }
    }

    public fun checkRootHeuristics(): Boolean {
        val suspiciousPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/system/app/Magisk.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su",
            "/data/adb/ksu",
            "/data/adb/magisk"
        )
        for (path in suspiciousPaths) {
            try {
                if (File(path).exists()) return true
            } catch (_: Exception) {}
        }

        val buildTags = Build.TAGS
        if (buildTags != null && buildTags.contains("test-keys")) {
            return true
        }

        // Check if su is in PATH directories
        val paths = System.getenv("PATH")?.split(":") ?: emptyList()
        for (p in paths) {
            try {
                val file = File(p, "su")
                if (file.exists()) return true
            } catch (_: Exception) {}
        }

        // Check for root management packages
        val rootPackages = listOf(
            "com.topjohnwu.magisk",
            "io.github.vvb2060.magisk",
            "me.weishu.kernelsu",
            "com.noshufou.android.su",
            "com.koushikdutta.superuser",
            "com.thirdparty.superuser",
            "com.kingroot.kinguser"
        )
        val pm = context.packageManager
        for (pkg in rootPackages) {
            try {
                pm.getPackageInfo(pkg, 0)
                return true
            } catch (_: PackageManager.NameNotFoundException) {
            } catch (_: Exception) {}
        }

        // Check executing which su
        try {
            val process = Runtime.getRuntime().exec(arrayOf("which", "su"))
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val line = reader.readLine()
            reader.close()
            process.destroy()
            if (!line.isNullOrBlank()) return true
        } catch (_: Exception) {}

        return false
    }

    public fun checkEmulator(): Boolean {
        val fp = Build.FINGERPRINT ?: ""
        val model = Build.MODEL ?: ""
        val manufacturer = Build.MANUFACTURER ?: ""
        val brand = Build.BRAND ?: ""
        val device = Build.DEVICE ?: ""
        val product = Build.PRODUCT ?: ""
        val hardware = Build.HARDWARE ?: ""

        return (fp.startsWith("generic")
                || fp.startsWith("unknown")
                || model.contains("google_sdk", ignoreCase = true)
                || model.contains("Emulator", ignoreCase = true)
                || model.contains("Android SDK built for x86", ignoreCase = true)
                || manufacturer.contains("Genymotion", ignoreCase = true)
                || (brand.startsWith("generic") && device.startsWith("generic"))
                || "google_sdk" == product
                || product.contains("sdk_gphone", ignoreCase = true)
                || product.contains("vbox86p", ignoreCase = true)
                || hardware.contains("goldfish", ignoreCase = true)
                || hardware.contains("ranchu", ignoreCase = true)
                || hardware.contains("vbox86", ignoreCase = true)
                || hardware.contains("cuttlefish", ignoreCase = true))
    }
}

