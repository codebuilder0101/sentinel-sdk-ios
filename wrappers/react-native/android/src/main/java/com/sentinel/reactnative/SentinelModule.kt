package com.sentinel.reactnative

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap
import com.sentinel.sdk.SentinelSDK
import com.sentinel.sdk.collectors.PersonalDataValidator
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject

class SentinelModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String = "SentinelModule"

    @ReactMethod
    fun initialize(apiKey: String, environment: String, promise: Promise) {
        try {
            SentinelSDK.initialize(reactContext, apiKey, environment)
            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("INIT_ERROR", e.message, e)
        }
    }

    @ReactMethod
    fun capture(optionsMap: ReadableMap, promise: Promise) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val sdk = SentinelSDK.getInstance()
                val userDataMap = if (optionsMap.hasKey("userData")) optionsMap.getMap("userData") else null
                val fullName = userDataMap?.getString("fullName") ?: ""
                val documentId = if (userDataMap?.hasKey("documentId") == true) userDataMap.getString("documentId") else null
                val email = if (userDataMap?.hasKey("email") == true) userDataMap.getString("email") else null
                val phoneNumber = if (userDataMap?.hasKey("phoneNumber") == true) userDataMap.getString("phoneNumber") else null
                val timeoutMs = if (optionsMap.hasKey("timeoutMs")) optionsMap.getDouble("timeoutMs").toLong() else 5000L

                val captureOptions = SentinelSDK.CaptureOptions(
                    userData = PersonalDataValidator.Input(
                        fullName = fullName,
                        documentId = documentId,
                        email = email,
                        phoneNumber = phoneNumber
                    ),
                    locationTimeoutMs = timeoutMs,
                    wrapper = "react-native"
                )

                val jsonResponse = sdk.captureJson(captureOptions)
                val jsonObject = JSONObject(jsonResponse)
                val writableMap = convertJsonToMap(jsonObject)

                promise.resolve(writableMap)
            } catch (e: Exception) {
                promise.reject("CAPTURE_ERROR", e.message, e)
            }
        }
    }

    private fun convertJsonToMap(jsonObject: JSONObject): WritableMap {
        val map = Arguments.createMap()
        val iterator = jsonObject.keys()
        while (iterator.hasNext()) {
            val key = iterator.next()
            when (val value = jsonObject.get(key)) {
                is JSONObject -> map.putMap(key, convertJsonToMap(value))
                is JSONArray -> map.putArray(key, convertJsonToArray(value))
                is Boolean -> map.putBoolean(key, value)
                is Int -> map.putInt(key, value)
                is Double -> map.putDouble(key, value)
                is Long -> map.putDouble(key, value.toDouble())
                is String -> map.putString(key, value)
                JSONObject.NULL -> map.putNull(key)
                else -> map.putString(key, value.toString())
            }
        }
        return map
    }

    private fun convertJsonToArray(jsonArray: JSONArray): com.facebook.react.bridge.WritableArray {
        val array = Arguments.createArray()
        for (i in 0 until jsonArray.length()) {
            when (val value = jsonArray.get(i)) {
                is JSONObject -> array.pushMap(convertJsonToMap(value))
                is JSONArray -> array.pushArray(convertJsonToArray(value))
                is Boolean -> array.pushBoolean(value)
                is Int -> array.pushInt(value)
                is Double -> array.pushDouble(value)
                is Long -> array.pushDouble(value.toDouble())
                is String -> array.pushString(value)
                JSONObject.NULL -> array.pushNull()
                else -> array.pushString(value.toString())
            }
        }
        return array
    }
}
