package com.sentinel.sdk.collectors

import android.content.Context
import android.content.pm.PackageManager
import com.sentinel.sdk.models.SentinelDetectedApp
import com.sentinel.sdk.models.SentinelInstalledApps

class AppDetectionCollector(private val context: Context) {

    data class TargetApp(
        val id: String,
        val name: String,
        val packageName: String,
        val category: String = "gambling_betting"
    )

    companion object {
        val DEFAULT_TARGETS = listOf(
            TargetApp("bet365", "bet365", "com.bet365.app"),
            TargetApp("novibet", "Novibet", "gr.novibet"),
            TargetApp("sportingbet", "Sportingbet Livescore", "com.sportingbet.sportsbook"),
            TargetApp("superbets", "Superbets", "com.superbet.app"),
            TargetApp("kto", "KTO", "com.kto.sports"),
            TargetApp("betano", "Betano", "com.betano.app"),
            TargetApp("betfair", "Betfair", "com.betfair.sportsbook"),
            TargetApp("betsson", "Betsson", "com.betsson.sportsbook"),
            TargetApp("rivalo", "Rivalo", "com.rivalo.app"),
            TargetApp("onexbet", "1xBet", "com.onexbet.mobile"),
            TargetApp("galerabet", "Galera.bet", "com.galerabet.app"),
            TargetApp("pixbet", "Pixbet", "com.pixbet.app"),
            TargetApp("estrelabet", "EstrelaBet", "com.estrelabet.app"),
            TargetApp("pinnacle", "Pinnacle Sports", "com.pinnacle.sportsbook"),
            TargetApp("pokerstars", "PokerStars", "com.pyrsoftware.pokerstars"),
            TargetApp("betway", "Betway", "com.betway.sports"),
            TargetApp("bwin", "bwin Sportsbook", "com.bwin.sports"),
            TargetApp("unibet", "Unibet", "com.unibet.sportsbook"),
            TargetApp("williamhill", "William Hill", "com.williamhill.sports"),
            TargetApp("paddypower", "Paddy Power", "com.paddypower.sports"),
            TargetApp("ladbrokes", "Ladbrokes", "com.ladbrokes.sports"),
            TargetApp("coral", "Coral Sports", "com.coral.sports"),
            TargetApp("dafabet", "Dafabet", "com.dafabet.sports"),
            TargetApp("stake", "Stake", "com.stake.app"),
            TargetApp("blaze", "Blaze", "com.blaze.mobile")
        )
    }

    fun scan(targets: List<TargetApp> = DEFAULT_TARGETS): SentinelInstalledApps {
        val pm = context.packageManager
        val detected = mutableListOf<SentinelDetectedApp>()

        for (target in targets) {
            val isInstalled = try {
                pm.getPackageInfo(target.packageName, 0)
                true
            } catch (e: PackageManager.NameNotFoundException) {
                false
            } catch (e: Exception) {
                false
            }

            if (isInstalled) {
                detected.add(
                    SentinelDetectedApp(
                        targetId = target.id,
                        appName = target.name,
                        category = target.category,
                        detectionIdentifier = target.packageName,
                        detectionMethod = "package_manager_query",
                        isDetected = true
                    )
                )
            }
        }

        val hasBetting = detected.isNotEmpty()
        val riskLevel = if (hasBetting) "FLAGGED" else "CLEAN"

        return SentinelInstalledApps(
            scanStrategy = "targeted_manifest_queries",
            totalTargetsScanned = targets.size,
            totalDetected = detected.size,
            riskLevel = riskLevel,
            hasBettingApps = hasBetting,
            detectedApps = detected,
            unresolvedSchemesCount = 0
        )
    }
}
