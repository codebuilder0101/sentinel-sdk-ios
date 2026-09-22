package com.sentinel.sdk.collectors

import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Looper
import androidx.core.content.ContextCompat
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
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

    companion object {
        private const val FRESHNESS_THRESHOLD_MS = 60_000L // 1 minute
    }

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

        val location = withTimeoutOrNull(timeoutMs) {
            // 1. Try Google Play Services Fused Location Provider
            fetchFusedLocation() ?: fetchActiveLocationManagerLocation() ?: getBestCachedLocation()
        } ?: getBestCachedLocation() // If timed out, fallback to best cached location if available

        return if (location != null) {
            val isMock = isLocationMocked(location)

            SentinelLocationData(
                status = "SUCCESS",
                permissionStatus = permStatus,
                coordinates = SentinelCoordinates(
                    latitude = location.latitude,
                    longitude = location.longitude,
                    accuracyMeters = location.accuracy.toDouble(),
                    altitudeMeters = if (location.hasAltitude()) location.altitude else null,
                    altitudeAccuracyMeters = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && location.hasVerticalAccuracy()) location.verticalAccuracyMeters.toDouble() else null,
                    headingDegrees = if (location.hasBearing()) location.bearing.toDouble() else null,
                    speedMps = if (location.hasSpeed()) location.speed.toDouble() else null
                ),
                timestamp = currentIsoTimestamp(location.time),
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

    @SuppressLint("MissingPermission")
    private suspend fun fetchFusedLocation(): Location? {
        return try {
            val fusedClient = LocationServices.getFusedLocationProviderClient(context)
            val cts = CancellationTokenSource()
            val priority = Priority.PRIORITY_HIGH_ACCURACY

            suspendCancellableCoroutine { cont ->
                cont.invokeOnCancellation { cts.cancel() }
                fusedClient.getCurrentLocation(priority, cts.token)
                    .addOnSuccessListener { loc ->
                        if (cont.isActive) cont.resume(loc)
                    }
                    .addOnFailureListener {
                        if (cont.isActive) cont.resume(null)
                    }
                    .addOnCanceledListener {
                        if (cont.isActive) cont.resume(null)
                    }
            }
        } catch (e: Exception) {
            null
        }
    }

    @SuppressLint("MissingPermission")
    private suspend fun fetchActiveLocationManagerLocation(): Location? {
        val lm = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return null

        return suspendCancellableCoroutine { cont ->
            val listener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    try { lm.removeUpdates(this) } catch (_: Exception) {}
                    if (cont.isActive) cont.resume(location)
                }

                @Deprecated("Deprecated in Java")
                override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                override fun onProviderEnabled(provider: String) {}
                override fun onProviderDisabled(provider: String) {}
            }

            cont.invokeOnCancellation {
                try { lm.removeUpdates(listener) } catch (_: Exception) {}
            }

            var requested = false
            val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
            for (provider in providers) {
                if (lm.isProviderEnabled(provider)) {
                    try {
                        lm.requestLocationUpdates(provider, 0L, 0f, listener, Looper.getMainLooper())
                        requested = true
                    } catch (_: Exception) {}
                }
            }

            if (!requested && cont.isActive) {
                cont.resume(null)
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun getBestCachedLocation(): Location? {
        val lm = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return null
        val now = System.currentTimeMillis()

        val gpsLoc = try { lm.getLastKnownLocation(LocationManager.GPS_PROVIDER) } catch (_: Exception) { null }
        val netLoc = try { lm.getLastKnownLocation(LocationManager.NETWORK_PROVIDER) } catch (_: Exception) { null }
        val passiveLoc = try { lm.getLastKnownLocation(LocationManager.PASSIVE_PROVIDER) } catch (_: Exception) { null }

        val candidates = listOfNotNull(gpsLoc, netLoc, passiveLoc)
        if (candidates.isEmpty()) return null

        // Score candidates based on freshness and accuracy
        return candidates.minByOrNull { loc ->
            val ageMs = (now - loc.time).coerceAtLeast(0L)
            // Weight: age in seconds + accuracy in meters
            (ageMs / 1000.0) * 0.5 + loc.accuracy
        }
    }

    private fun isLocationMocked(location: Location): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            location.isMock
        } else {
            @Suppress("DEPRECATION")
            location.isFromMockProvider
        }
    }

    private fun currentIsoTimestamp(timeMs: Long = System.currentTimeMillis()): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        sdf.timeZone = TimeZone.getTimeZone("UTC")
        return sdf.format(Date(timeMs))
    }
}

