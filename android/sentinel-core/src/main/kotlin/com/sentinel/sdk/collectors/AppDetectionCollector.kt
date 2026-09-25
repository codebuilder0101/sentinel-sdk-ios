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
            TargetApp("superbets", "Superbet", "com.superbet.app"),
            TargetApp("sportybet", "SportyBet", "com.sportybet.android"),
            TargetApp("betano", "Betano", "com.betano.app"),
            TargetApp("novibet", "Novibet", "gr.novibet"),
            TargetApp("sportingbet", "Sportingbet Livescore", "com.sportingbet.sportsbook"),
            TargetApp("kto", "KTO", "com.kto.sports"),
            TargetApp("betfair", "Betfair", "com.betfair.sportsbook"),
            TargetApp("betsson", "Betsson", "com.betsson.sportsbook"),
            TargetApp("rivalo", "Rivalo", "com.rivalo.app"),
            TargetApp("onexbet", "1xBet", "com.onexbet.mobile"),
            TargetApp("galera_bet", "Galera.bet", "com.galerabet.app"),
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

        val KNOWN_APP_REGISTRY: Map<String, List<TargetApp>> = mapOf(
            "bet365" to listOf(
                TargetApp("bet365", "bet365", "com.bet365.app"),
                TargetApp("bet365_wrapper", "bet365 Wrapper", "com.bet365Wrapper.Bet365_Application")
            ),
            "superbet" to listOf(
                TargetApp("superbets", "Superbet", "com.superbet.app"),
                TargetApp("superbet_ro", "Superbet RO", "ro.superbet.app")
            ),
            "superbets" to listOf(
                TargetApp("superbets", "Superbet", "com.superbet.app")
            ),
            "sportybet" to listOf(
                TargetApp("sportybet", "SportyBet", "com.sportybet.android"),
                TargetApp("sportybet_app", "SportyBet App", "com.sportybet.app")
            ),
            "sporty bet" to listOf(
                TargetApp("sportybet", "SportyBet", "com.sportybet.android"),
                TargetApp("sportybet_app", "SportyBet App", "com.sportybet.app")
            ),
            "betano" to listOf(
                TargetApp("betano", "Betano", "com.betano.app"),
                TargetApp("betano_de", "Betano Sports", "de.betano.sports")
            ),
            "novibet" to listOf(TargetApp("novibet", "Novibet", "gr.novibet")),
            "sportingbet" to listOf(TargetApp("sportingbet", "Sportingbet Livescore", "com.sportingbet.sportsbook")),
            "kto" to listOf(TargetApp("kto", "KTO", "com.kto.sports")),
            "betfair" to listOf(TargetApp("betfair", "Betfair", "com.betfair.sportsbook")),
            "betsson" to listOf(TargetApp("betsson", "Betsson", "com.betsson.sportsbook")),
            "rivalo" to listOf(TargetApp("rivalo", "Rivalo", "com.rivalo.app")),
            "1xbet" to listOf(TargetApp("onexbet", "1xBet", "com.onexbet.mobile")),
            "onexbet" to listOf(TargetApp("onexbet", "1xBet", "com.onexbet.mobile")),
            "galera_bet" to listOf(TargetApp("galera_bet", "Galera.bet", "com.galerabet.app")),
            "galerabet" to listOf(TargetApp("galera_bet", "Galera.bet", "com.galerabet.app")),
            "galera.bet" to listOf(TargetApp("galera_bet", "Galera.bet", "com.galerabet.app")),
            "pixbet" to listOf(TargetApp("pixbet", "Pixbet", "com.pixbet.app")),
            "estrelabet" to listOf(TargetApp("estrelabet", "EstrelaBet", "com.estrelabet.app")),
            "pinnacle" to listOf(TargetApp("pinnacle", "Pinnacle Sports", "com.pinnacle.sportsbook")),
            "pokerstars" to listOf(TargetApp("pokerstars", "PokerStars", "com.pyrsoftware.pokerstars")),
            "betway" to listOf(TargetApp("betway", "Betway", "com.betway.sports")),
            "bwin" to listOf(TargetApp("bwin", "bwin Sportsbook", "com.bwin.sports")),
            "unibet" to listOf(TargetApp("unibet", "Unibet", "com.unibet.sportsbook")),
            "williamhill" to listOf(TargetApp("williamhill", "William Hill", "com.williamhill.sports")),
            "william hill" to listOf(TargetApp("williamhill", "William Hill", "com.williamhill.sports")),
            "paddypower" to listOf(TargetApp("paddypower", "Paddy Power", "com.paddypower.sports")),
            "paddy power" to listOf(TargetApp("paddypower", "Paddy Power", "com.paddypower.sports")),
            "ladbrokes" to listOf(TargetApp("ladbrokes", "Ladbrokes", "com.ladbrokes.sports")),
            "coral" to listOf(TargetApp("coral", "Coral Sports", "com.coral.sports")),
            "dafabet" to listOf(TargetApp("dafabet", "Dafabet", "com.dafabet.sports")),
            "stake" to listOf(TargetApp("stake", "Stake", "com.stake.app")),
            "blaze" to listOf(TargetApp("blaze", "Blaze", "com.blaze.mobile")),
            // Common apps for live testing verification
            "whatsapp" to listOf(TargetApp("whatsapp", "WhatsApp", "com.whatsapp", category = "messaging")),
            "chrome" to listOf(TargetApp("chrome", "Google Chrome", "com.android.chrome", category = "browser")),
            "youtube" to listOf(TargetApp("youtube", "YouTube", "com.google.android.youtube", category = "media")),
            "instagram" to listOf(TargetApp("instagram", "Instagram", "com.instagram.android", category = "social")),
            "telegram" to listOf(TargetApp("telegram", "Telegram", "org.telegram.messenger", category = "messaging"))
        )

        /**
         * Resolves a user-provided string of app names or package IDs into a list of [TargetApp]s.
         * Supports:
         * - Comma-separated or newline-separated app names (e.g. "bet365, Superbet, SportyBet, Betano")
         * - Direct package names (e.g. "com.sportybet.android")
         * - "Name:package" or "Name (package)" formats
         */
        fun parseTargetsFromInput(input: String): List<TargetApp> {
            val tokens = input.split(',', '\n', ';')
                .map { it.trim() }
                .filter { it.isNotEmpty() }

            if (tokens.isEmpty()) {
                return DEFAULT_TARGETS
            }

            val result = mutableListOf<TargetApp>()
            for (token in tokens) {
                // Format: "Name:package.name" or "Name (package.name)"
                if (token.contains(":") || (token.contains("(") && token.contains(")"))) {
                    val name: String
                    val pkg: String
                    if (token.contains(":")) {
                        val parts = token.split(":", limit = 2)
                        name = parts[0].trim()
                        pkg = parts[1].trim()
                    } else {
                        name = token.substringBefore("(").trim()
                        pkg = token.substringAfter("(").substringBefore(")").trim()
                    }
                    val id = name.lowercase().replace("[^a-z0-9_]".toRegex(), "_")
                    result.add(TargetApp(id = id, name = name, packageName = pkg))
                    continue
                }

                // Format: Direct package name (e.g., com.example.app)
                if (token.contains(".") && !token.contains(" ")) {
                    val id = token.substringAfterLast('.').lowercase()
                    result.add(TargetApp(id = id, name = token, packageName = token))
                    continue
                }

                // Registry lookup by lowercase normalized name
                val normalizedKey = token.lowercase().trim()
                val matched = KNOWN_APP_REGISTRY[normalizedKey]
                if (matched != null) {
                    result.addAll(matched)
                } else {
                    // Match against DEFAULT_TARGETS
                    val defaultMatches = DEFAULT_TARGETS.filter {
                        it.name.equals(token, ignoreCase = true) || it.id.equals(token, ignoreCase = true)
                    }
                    if (defaultMatches.isNotEmpty()) {
                        result.addAll(defaultMatches)
                    } else {
                        // Dynamic fallback target
                        val cleanId = token.lowercase().replace("[^a-z0-9_]".toRegex(), "_")
                        result.add(
                            TargetApp(
                                id = cleanId,
                                name = token,
                                packageName = "com.$cleanId.app"
                            )
                        )
                    }
                }
            }
            return result.distinctBy { it.packageName }
        }
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
