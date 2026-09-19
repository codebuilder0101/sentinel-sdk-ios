package com.sentinel.reactnative

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.sentinel.sdk.SentinelSDK
import com.sentinel.sdk.collectors.PersonalDataValidator
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class SentinelModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String = "SentinelModule"

    @ReactMethod
    fun initialize(apiKey: String, environment: String, promise: Promise) {
        try {
            SentinelSDK.initialize(reactContext, apiKey)
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
                val userDataMap = optionsMap.getMap("userData")
                val fullName = userDataMap?.getString("fullName") ?: ""
                val documentId = userDataMap?.getString("documentId")
                val email = userDataMap?.getString("email")
                val phoneNumber = userDataMap?.getString("phoneNumber")
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
                promise.resolve(jsonResponse)
            } catch (e: Exception) {
                promise.reject("CAPTURE_ERROR", e.message, e)
            }
        }
    }
}
