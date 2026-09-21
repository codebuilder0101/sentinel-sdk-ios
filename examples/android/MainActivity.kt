package com.sentinel.example

import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.sentinel.sdk.SentinelSDK
import com.sentinel.sdk.collectors.PersonalDataValidator
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {

    private lateinit var captureButton: Button
    private lateinit var progressBar: ProgressBar
    private lateinit var resultTextView: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        captureButton = findViewById(R.id.btn_capture)
        progressBar = findViewById(R.id.progress_bar)
        resultTextView = findViewById(R.id.tv_result)

        // 1. Initialize Sentinel SDK
        SentinelSDK.initialize(
            context = this,
            apiKey = "test_client_api_key_12345",
            environment = "production"
        )

        captureButton.setOnClickListener {
            runSentinelCapture()
        }
    }

    private fun runSentinelCapture() {
        progressBar.visibility = View.VISIBLE
        captureButton.isEnabled = false

        val input = PersonalDataValidator.Input(
            fullName = "Carlos Eduardo da Silva",
            documentId = "123.456.789-09",
            email = "carlos.silva@example.com",
            phoneNumber = "+5511999998888"
        )

        val options = SentinelSDK.CaptureOptions(
            userData = input,
            locationTimeoutMs = 5000L,
            wrapper = "native"
        )

        lifecycleScope.launch {
            try {
                val sdk = SentinelSDK.getInstance()
                val jsonResult = sdk.captureJson(options)

                progressBar.visibility = View.GONE
                captureButton.isEnabled = true
                resultTextView.text = jsonResult
            } catch (e: Exception) {
                progressBar.visibility = View.GONE
                captureButton.isEnabled = true
                resultTextView.text = "Error: ${e.localizedMessage}"
            }
        }
    }
}
