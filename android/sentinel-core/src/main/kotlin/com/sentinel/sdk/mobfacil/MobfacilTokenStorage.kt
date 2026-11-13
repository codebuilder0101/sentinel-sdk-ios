package com.sentinel.sdk.mobfacil

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Storage abstraction for persisting authentication tokens across application restarts.
 */
interface MobfacilTokenStorage {
    suspend fun loadToken(): MobfacilToken?
    suspend fun saveToken(token: MobfacilToken)
    suspend fun clearToken()
}

/**
 * Persistent storage backed by Android SharedPreferences.
 */
class SharedPreferencesMobfacilTokenStorage(
    context: Context,
    prefsName: String = "com.sentinel.mobfacil.prefs",
    private val key: String = "auth_token"
) : MobfacilTokenStorage {

    private val prefs: SharedPreferences = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    override suspend fun loadToken(): MobfacilToken? = withContext(Dispatchers.IO) {
        val serialized = prefs.getString(key, null) ?: return@withContext null
        try {
            json.decodeFromString<MobfacilToken>(serialized)
        } catch (e: Exception) {
            null
        }
    }

    override suspend fun saveToken(token: MobfacilToken): Unit = withContext(Dispatchers.IO) {
        val serialized = json.encodeToString(token)
        prefs.edit().putString(key, serialized).apply()
    }

    override suspend fun clearToken(): Unit = withContext(Dispatchers.IO) {
        prefs.edit().remove(key).apply()
    }
}

/**
 * In-memory storage for testing or non-persisted sessions.
 */
class InMemoryMobfacilTokenStorage(
    private var initialToken: MobfacilToken? = null
) : MobfacilTokenStorage {

    @Volatile
    private var token: MobfacilToken? = initialToken

    override suspend fun loadToken(): MobfacilToken? = token

    override suspend fun saveToken(token: MobfacilToken) {
        this.token = token
    }

    override suspend fun clearToken() {
        this.token = null
    }
}

