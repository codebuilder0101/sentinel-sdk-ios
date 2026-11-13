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
            TargetApp("bet365_br", "bet365 Brazil", "com.bet365SportsBR.Bet365_Application"),
            TargetApp("superbets", "Superbet", "com.superbet.app"),
            TargetApp("superbet_br", "Superbet Brazil", "br.bet.superbet.sport"),
            TargetApp("sportybet", "SportyBet", "com.sportybet.android"),
            TargetApp("sportybet_br", "SportyBet Brazil", "com.sportybet.android.gp.brazil"),
            TargetApp("betano", "Betano", "com.betano.app"),
            TargetApp("betano_br", "Betano Brazil", "com.kaizengaming.betano.brazil"),
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
                TargetApp("bet365_br", "bet365 Brazil", "com.bet365SportsBR.Bet365_Application"),
                TargetApp("bet365_wrapper", "bet365 Wrapper", "com.bet365Wrapper.Bet365_Application")
            ),
            "bet365 brazil" to listOf(
                TargetApp("bet365_br", "bet365 Brazil", "com.bet365SportsBR.Bet365_Application"),
                TargetApp("bet365", "bet365", "com.bet365.app")
            ),
            "bet365 br" to listOf(
                TargetApp("bet365_br", "bet365 Brazil", "com.bet365SportsBR.Bet365_Application"),
                TargetApp("bet365", "bet365", "com.bet365.app")
            ),
            "superbet" to listOf(
                TargetApp("superbets", "Superbet", "com.superbet.app"),
                TargetApp("superbet_br", "Superbet Brazil", "br.bet.superbet.sport"),
                TargetApp("superbet_rs_sport", "Superbet RS Sport", "rs.superbet.sport"),
                TargetApp("superbet_rs_games", "Superbet RS Games", "rs.superbet.games"),
                TargetApp("superbet_ro_sport", "Superbet RO Sport", "ro.superbet.sport"),
                TargetApp("superbet_ro_games", "Superbet RO Games", "ro.superbet.games"),
                TargetApp("superbet_ro_club", "Superbet RO Club", "ro.superbet.club"),
                TargetApp("superbet_ro", "Superbet RO", "ro.superbet.app"),
                TargetApp("superbet_pl_sport", "Superbet PL Sport", "pl.superbet.sport"),
                TargetApp("superbet_pl_app", "Superbet PL App", "pl.superbet.app"),
                TargetApp("superbet_android", "Superbet Android", "com.superbet.android")
            ),
            "superbets" to listOf(
                TargetApp("superbets", "Superbet", "com.superbet.app"),
                TargetApp("superbet_br", "Superbet Brazil", "br.bet.superbet.sport"),
                TargetApp("superbet_rs_sport", "Superbet RS Sport", "rs.superbet.sport"),
                TargetApp("superbet_rs_games", "Superbet RS Games", "rs.superbet.games"),
                TargetApp("superbet_ro_sport", "Superbet RO Sport", "ro.superbet.sport"),
                TargetApp("superbet_ro_games", "Superbet RO Games", "ro.superbet.games"),
                TargetApp("superbet_ro_club", "Superbet RO Club", "ro.superbet.club"),
                TargetApp("superbet_ro", "Superbet RO", "ro.superbet.app"),
                TargetApp("superbet_pl_sport", "Superbet PL Sport", "pl.superbet.sport"),
                TargetApp("superbet_pl_app", "Superbet PL App", "pl.superbet.app"),
                TargetApp("superbet_android", "Superbet Android", "com.superbet.android")
            ),
            "superbet brazil" to listOf(
                TargetApp("superbet_br", "Superbet Brazil", "br.bet.superbet.sport"),
                TargetApp("superbets", "Superbet", "com.superbet.app")
            ),
            "superbet br" to listOf(
                TargetApp("superbet_br", "Superbet Brazil", "br.bet.superbet.sport"),
                TargetApp("superbets", "Superbet", "com.superbet.app")
            ),
            "sportybet" to listOf(
                TargetApp("sportybet", "SportyBet", "com.sportybet.android"),
                TargetApp("sportybet_br", "SportyBet Brazil", "com.sportybet.android.gp.brazil"),
                TargetApp("sportybet_app", "SportyBet App", "com.sportybet.app")
            ),
            "sporty bet" to listOf(
                TargetApp("sportybet", "SportyBet", "com.sportybet.android"),
                TargetApp("sportybet_br", "SportyBet Brazil", "com.sportybet.android.gp.brazil"),
                TargetApp("sportybet_app", "SportyBet App", "com.sportybet.app")
            ),
            "sportybet brazil" to listOf(
                TargetApp("sportybet_br", "SportyBet Brazil", "com.sportybet.android.gp.brazil"),
                TargetApp("sportybet", "SportyBet", "com.sportybet.android")
            ),
            "sportybet br" to listOf(
                TargetApp("sportybet_br", "SportyBet Brazil", "com.sportybet.android.gp.brazil"),
                TargetApp("sportybet", "SportyBet", "com.sportybet.android")
            ),
            "betano" to listOf(
                TargetApp("betano", "Betano", "com.betano.app"),
                TargetApp("betano_br", "Betano Brazil", "com.kaizengaming.betano.brazil"),
                TargetApp("betano_de", "Betano Sports", "de.betano.sports")
            ),
            "betano brazil" to listOf(
                TargetApp("betano_br", "Betano Brazil", "com.kaizengaming.betano.brazil"),
                TargetApp("betano", "Betano", "com.betano.app")
            ),
            "betano br" to listOf(
                TargetApp("betano_br", "Betano Brazil", "com.kaizengaming.betano.brazil"),
                TargetApp("betano", "Betano", "com.betano.app")
            ),
            "kaizen" to listOf(
                TargetApp("betano_br", "Betano Brazil", "com.kaizengaming.betano.brazil"),
                TargetApp("betano", "Betano", "com.betano.app")
            ),
            "kaizengaming" to listOf(
                TargetApp("betano_br", "Betano Brazil", "com.kaizengaming.betano.brazil"),
                TargetApp("betano", "Betano", "com.betano.app")
            ),
            "kaizen gaming" to listOf(
                TargetApp("betano_br", "Betano Brazil", "com.kaizengaming.betano.brazil"),
                TargetApp("betano", "Betano", "com.betano.app")
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
         * Computes Levenshtein edit distance between two strings.
         */
        fun levenshteinDistance(s1: String, s2: String): Int {
            val m = s1.length
            val n = s2.length
            val dp = Array(m + 1) { IntArray(n + 1) }

            for (i in 0..m) dp[i][0] = i
            for (j in 0..n) dp[0][j] = j

            for (i in 1..m) {
                for (j in 1..n) {
                    val cost = if (s1[i - 1] == s2[j - 1]) 0 else 1
                    dp[i][j] = minOf(
                        dp[i - 1][j] + 1,       // deletion
                        dp[i][j - 1] + 1,       // insertion
                        dp[i - 1][j - 1] + cost // substitution
                    )
                }
            }
            return dp[m][n]
        }

        /**
         * Normalizes a string for comparison by lowercasing and stripping non-alphanumeric characters.
         */
        fun normalizeKey(input: String): String {
            return input.lowercase().replace("[^a-z0-9]".toRegex(), "")
        }

        /**
         * Resolves a search term against KNOWN_APP_REGISTRY using:
         * 1. Exact direct key match
         * 2. Normalized alphanumeric match (ignores spaces, hyphens, punctuation)
         * 3. Substring containment match (e.g. "superbet live" or "bet365 official")
         * 4. Levenshtein fuzzy match for typo auto-correction (e.g. "suprbet", "bte365", "sporty bet", "betanoo")
         */
        fun findFuzzyMatches(query: String): List<TargetApp>? {
            val normalizedQuery = normalizeKey(query)
            if (normalizedQuery.isEmpty()) return null

            // 1. Direct registry lookup
            val lowerQuery = query.lowercase().trim()
            KNOWN_APP_REGISTRY[lowerQuery]?.let { return it }

            // 2. Normalized key match (e.g. "bet-365" == "bet365", "super bet" == "superbet")
            for ((key, targets) in KNOWN_APP_REGISTRY) {
                if (normalizeKey(key) == normalizedQuery) {
                    return targets
                }
            }

            // 3. Substring containment (if length >= 4)
            for ((key, targets) in KNOWN_APP_REGISTRY) {
                val normKey = normalizeKey(key)
                if (normKey.length >= 4 && (normalizedQuery.contains(normKey) || normKey.contains(normalizedQuery))) {
                    return targets
                }
            }

            // 4. Fuzzy Levenshtein matching for typo auto-correction
            var bestDistance = Int.MAX_VALUE
            var bestMatch: List<TargetApp>? = null

            for ((key, targets) in KNOWN_APP_REGISTRY) {
                val normKey = normalizeKey(key)
                val dist = levenshteinDistance(normalizedQuery, normKey)

                // Threshold: allow 1 typo for short keys (<=4 chars), 2 typos for longer keys (>4 chars)
                val maxAllowedDistance = if (normKey.length <= 4) 1 else 2

                if (dist <= maxAllowedDistance && dist < bestDistance) {
                    bestDistance = dist
                    bestMatch = targets
                }
            }

            return bestMatch
        }

        /**
         * Resolves a user-provided string of app names or package IDs into a list of [TargetApp]s.
         * Supports:
         * - Comma-separated or newline-separated app names (e.g. "bet365, Superbet, SportyBet, Betano")
         * - Fuzzy matching / typo auto-correction (e.g. "suprbet", "bet 365", "sporty-bet")
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

                // Format: Direct package name (e.g., com.example.app, rs.superbet.sport)
                if (token.contains(".") && !token.contains(" ")) {
                    val id = token.substringAfterLast('.').lowercase()
                    result.add(TargetApp(id = id, name = token, packageName = token))
                    continue
                }

                // 1. Check fuzzy registry matching (exact, normalized, substring, or typo auto-correct)
                val fuzzyMatches = findFuzzyMatches(token)
                if (fuzzyMatches != null) {
                    result.addAll(fuzzyMatches)
                } else {
                    // 2. Match against DEFAULT_TARGETS
                    val defaultMatches = DEFAULT_TARGETS.filter {
                        it.name.equals(token, ignoreCase = true) ||
                        it.id.equals(token, ignoreCase = true) ||
                        normalizeKey(it.name) == normalizeKey(token) ||
                        normalizeKey(it.id) == normalizeKey(token)
                    }
                    if (defaultMatches.isNotEmpty()) {
                        result.addAll(defaultMatches)
                    } else {
                        // 3. Dynamic fallback target
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
