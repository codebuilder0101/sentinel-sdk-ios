package com.sentinel.sdk.collectors

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import androidx.core.content.ContextCompat
import com.sentinel.sdk.models.SentinelCoordinates
import com.sentinel.sdk.models.SentinelLocationData
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.coroutines.resume

class LocationCollector(private val context: Context) {

    @SuppressLint("MissingPermission")
    suspend fun collectLocation(timeoutMs: Long = 5000L): SentinelLocationData {
        val hasFine = ContextCompat.checkSelfPermission(
            context,
            android.Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        val hasCoarse = ContextCompat.checkSelfPermission(
            context,
            android.Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        val permStatus = when {
            hasFine -> "granted_fine"
            hasCoarse -> "granted_coarse"
            else -> "denied"
        }

        if (!hasFine && !hasCoarse) {
            return SentinelLocationData(
                status = "PERMISSION_DENIED",
                permissionStatus = permStatus,
                coordinates = SentinelCoordinates(latitude = 0.0, longitude = 0.0, accuracyMeters = -1.0),
                timestamp = currentIsoTimestamp(),
                isMockLocation = false
            )
        }

        val lm = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            ?: return SentinelLocationData(
                status = "UNAVAILABLE",
                permissionStatus = permStatus,
                coordinates = SentinelCoordinates(latitude = 0.0, longitude = 0.0, accuracyMeters = -1.0),
                timestamp = currentIsoTimestamp(),
                isMockLocation = false
            )

        val loc = withTimeoutOrNull(timeoutMs) {
            suspendCancellableCoroutine<Location?> { cont ->
                val gpsLoc = try { lm.getLastKnownLocation(LocationManager.GPS_PROVIDER) } catch (e: Exception) { null }
                val netLoc = try { lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER) } catch (e: Exception) { null }
                val passiveLoc = try { lm.getLastKnownLocation(LocationManager.PASSIVE_PROVIDER) } catch (e: Exception) { null }

                // Pick the most accurate or freshest location
                val candidates = listOfNotNull(gpsLoc, netLoc, passiveLoc)
                val bestLoc = candidates.minByOrNull { it.accuracy }
                cont.resume(bestLoc)
            }
        }

        return if (loc != null) {
            val isMock = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                loc.isMock
            } else {
                @Suppress("DEPRECATION")
                loc.isFromMockProvider
            }

            SentinelLocationData(
                status = "SUCCESS",
                permissionStatus = permStatus,
                coordinates = SentinelCoordinates(
                    latitude = loc.latitude,
                    longitude = loc.longitude,
                    accuracyMeters = loc.accuracy.toDouble(),
                    altitudeMeters = if (loc.hasAltitude()) loc.altitude else null,
                    altitudeAccuracyMeters = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O && loc.hasVerticalAccuracy()) loc.verticalAccuracyMeters.toDouble() else null,
                    headingDegrees = if (loc.hasBearing()) loc.bearing.toDouble() else null,
                    speedMps = if (loc.hasSpeed()) loc.speed.toDouble() else null
                ),
                timestamp = currentIsoTimestamp(loc.time),
                isMockLocation = isMock
            )
        } else {
            SentinelLocationData(
                status = "TIMEOUT",
                permissionStatus = permStatus,
                coordinates = SentinelCoordinates(latitude = 0.0, longitude = 0.0, accuracyMeters = -1.0),
                timestamp = currentIsoTimestamp(),
                isMockLocation = false
            )
        }
    }

    private fun currentIsoTimestamp(timeMs: Long = System.currentTimeMillis()): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        sdf.timeZone = TimeZone.getTimeZone("UTC")
        return sdf.format(Date(timeMs))
    }
}
