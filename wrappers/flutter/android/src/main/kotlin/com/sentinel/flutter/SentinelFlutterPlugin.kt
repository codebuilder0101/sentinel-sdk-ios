package com.sentinel.flutter

import android.content.Context
import androidx.annotation.NonNull
import com.sentinel.sdk.SentinelSDK
import com.sentinel.sdk.collectors.PersonalDataValidator
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class SentinelFlutterPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.sentinel.sdk/channel")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> {
                val apiKey = call.argument<String>("apiKey") ?: ""
                try {
                    SentinelSDK.initialize(context, apiKey)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("INIT_ERROR", e.message, null)
                }
            }
            "capture" -> {
                CoroutineScope(Dispatchers.Main).launch {
                    try {
                        val sdk = SentinelSDK.getInstance()
                        val userDataMap = call.argument<Map<String, Any>>("userData")
                        val fullName = userDataMap?.get("fullName") as? String ?: ""
                        val documentId = userDataMap?.get("documentId") as? String
                        val email = userDataMap?.get("email") as? String
                        val phoneNumber = userDataMap?.get("phoneNumber") as? String
                        val timeoutMs = (call.argument<Int>("timeoutMs") ?: 5000).toLong()

                        val options = SentinelSDK.CaptureOptions(
                            userData = PersonalDataValidator.Input(
                                fullName = fullName,
                                documentId = documentId,
                                email = email,
                                phoneNumber = phoneNumber
                            ),
                            locationTimeoutMs = timeoutMs,
                            wrapper = "flutter"
                        )

                        val jsonResponse = sdk.captureJson(options)
                        result.success(jsonResponse)
                    } catch (e: Exception) {
                        result.error("CAPTURE_ERROR", e.message, null)
                    }
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
