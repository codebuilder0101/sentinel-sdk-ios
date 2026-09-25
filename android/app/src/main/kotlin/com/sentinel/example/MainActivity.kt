package com.sentinel.example

import android.Manifest
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.google.android.material.card.MaterialCardView
import com.sentinel.sdk.SentinelSDK
import com.sentinel.sdk.collectors.AppDetectionCollector
import com.sentinel.sdk.collectors.PersonalDataValidator
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {

    private lateinit var etFullName: EditText
    private lateinit var etDocumentId: EditText
    private lateinit var etEmail: EditText
    private lateinit var etPhoneNumber: EditText

    private lateinit var etTargetApps: EditText
    private lateinit var btnPresetFourApps: Button
    private lateinit var btnPresetAllBetting: Button
    private lateinit var btnPresetCommonApps: Button
    private lateinit var btnClearApps: Button

    private lateinit var btnFillValid: Button
    private lateinit var btnFillInvalid: Button
    private lateinit var btnCapture: Button
    private lateinit var btnCopyJson: Button
    private lateinit var progressBar: ProgressBar

    private lateinit var cardSummary: MaterialCardView
    private lateinit var tvSummaryRisk: TextView
    private lateinit var tvSummaryAppsCount: TextView
    private lateinit var tvSummaryUserValid: TextView
    private lateinit var tvSummaryLocation: TextView
    private lateinit var tvSummaryRoot: TextView

    private lateinit var cardAppDetectionResults: MaterialCardView
    private lateinit var tvAppDetectionSubtitle: TextView
    private lateinit var tvAppDetectionList: TextView

    private lateinit var tvResult: TextView

    private var lastJsonOutput: String? = null

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val fineGranted = permissions[Manifest.permission.ACCESS_FINE_LOCATION] ?: false
        val coarseGranted = permissions[Manifest.permission.ACCESS_COARSE_LOCATION] ?: false
        Log.d("SentinelDemo", "Location permission result: fine=$fineGranted, coarse=$coarseGranted")
        executeCapture()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Initialize SDK
        SentinelSDK.initialize(
            context = this,
            apiKey = "test_enterprise_api_key_12345",
            environment = "sandbox"
        )

        bindViews()
        setupListeners()
    }

    private fun bindViews() {
        etFullName = findViewById(R.id.et_full_name)
        etDocumentId = findViewById(R.id.et_document_id)
        etEmail = findViewById(R.id.et_email)
        etPhoneNumber = findViewById(R.id.et_phone_number)

        etTargetApps = findViewById(R.id.et_target_apps)
        btnPresetFourApps = findViewById(R.id.btn_preset_four_apps)
        btnPresetAllBetting = findViewById(R.id.btn_preset_all_betting)
        btnPresetCommonApps = findViewById(R.id.btn_preset_common_apps)
        btnClearApps = findViewById(R.id.btn_clear_apps)

        btnFillValid = findViewById(R.id.btn_fill_valid)
        btnFillInvalid = findViewById(R.id.btn_fill_invalid)
        btnCapture = findViewById(R.id.btn_capture)
        btnCopyJson = findViewById(R.id.btn_copy_json)
        progressBar = findViewById(R.id.progress_bar)

        cardSummary = findViewById(R.id.card_summary)
        tvSummaryRisk = findViewById(R.id.tv_summary_risk)
        tvSummaryAppsCount = findViewById(R.id.tv_summary_apps_count)
        tvSummaryUserValid = findViewById(R.id.tv_summary_user_valid)
        tvSummaryLocation = findViewById(R.id.tv_summary_location)
        tvSummaryRoot = findViewById(R.id.tv_summary_root)

        cardAppDetectionResults = findViewById(R.id.card_app_detection_results)
        tvAppDetectionSubtitle = findViewById(R.id.tv_app_detection_subtitle)
        tvAppDetectionList = findViewById(R.id.tv_app_detection_list)

        tvResult = findViewById(R.id.tv_result)
    }

    private fun setupListeners() {
        btnFillValid.setOnClickListener {
            etFullName.setText("Carlos Eduardo da Silva")
            etDocumentId.setText("123.456.789-09")
            etEmail.setText("carlos.silva@example.com")
            etPhoneNumber.setText("+5511999998888")
        }

        btnFillInvalid.setOnClickListener {
            etFullName.setText("Carlos")
            etDocumentId.setText("111.111.111-11")
            etEmail.setText("invalid-email-address")
            etPhoneNumber.setText("1234")
        }

        btnPresetFourApps.setOnClickListener {
            etTargetApps.setText("bet365, Superbet, SportyBet, Betano")
        }

        btnPresetAllBetting.setOnClickListener {
            val allBettingNames = AppDetectionCollector.DEFAULT_TARGETS.joinToString(", ") { it.name }
            etTargetApps.setText(allBettingNames)
        }

        btnPresetCommonApps.setOnClickListener {
            etTargetApps.setText("WhatsApp, Google Chrome, YouTube, Instagram, Telegram")
        }

        btnClearApps.setOnClickListener {
            etTargetApps.setText("")
        }

        btnCapture.setOnClickListener {
            checkPermissionsAndRun()
        }

        btnCopyJson.setOnClickListener {
            lastJsonOutput?.let { json ->
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                val clip = ClipData.newPlainText("Sentinel Payload", json)
                clipboard.setPrimaryClip(clip)
                Toast.makeText(this, "JSON copied to clipboard", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun checkPermissionsAndRun() {
        val fineLocation = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
        if (fineLocation != PackageManager.PERMISSION_GRANTED) {
            requestPermissionLauncher.launch(
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                )
            )
        } else {
            executeCapture()
        }
    }

    private fun executeCapture() {
        progressBar.visibility = View.VISIBLE
        btnCapture.isEnabled = false

        val input = PersonalDataValidator.Input(
            fullName = etFullName.text.toString().trim(),
            documentId = etDocumentId.text.toString().trim(),
            email = etEmail.text.toString().trim(),
            phoneNumber = etPhoneNumber.text.toString().trim()
        )

        val targetInput = etTargetApps.text.toString().trim()
        val targetsToScan = if (targetInput.isNotEmpty()) {
            AppDetectionCollector.parseTargetsFromInput(targetInput)
        } else {
            emptyList()
        }

        val options = SentinelSDK.CaptureOptions(
            userData = input,
            locationTimeoutMs = 5000L,
            wrapper = "native_demo",
            customTargets = targetsToScan
        )

        lifecycleScope.launch {
            try {
                val sdk = SentinelSDK.getInstance()
                val payload = sdk.capture(options)
                val jsonResult = SentinelSDK.formatJson(payload)

                lastJsonOutput = jsonResult
                Log.d("SentinelSDK", "Captured Payload:\n$jsonResult")

                // Update Summary Badges
                cardSummary.visibility = View.VISIBLE
                val riskEmoji = if (payload.installedApps.riskLevel == "CLEAN") "🟢 CLEAN" else "🔴 FLAGGED (${payload.installedApps.totalDetected} apps)"
                tvSummaryRisk.text = "• Risk Level: $riskEmoji"
                tvSummaryAppsCount.text = "• Target Apps: ${payload.installedApps.totalDetected} of ${payload.installedApps.totalTargetsScanned} detected on system"

                val userEmoji = if (payload.userData.validation.isValid) "🟢 Valid" else "🔴 Invalid (${payload.userData.validation.validationErrors.joinToString()})"
                tvSummaryUserValid.text = "• User Identity: $userEmoji"

                val locEmoji = if (payload.locationData.status == "SUCCESS") "🟢 GPS Lock (${payload.locationData.coordinates.latitude}, ${payload.locationData.coordinates.longitude})" else "🟡 ${payload.locationData.status}"
                tvSummaryLocation.text = "• Location: $locEmoji"

                val rootStatus = if (payload.deviceData.isJailbrokenOrRooted) "🔴 ROOTED" else "🟢 Unrooted"
                val mockStatus = if (payload.locationData.isMockLocation) "🔴 MOCK GPS" else "🟢 Real GPS"
                val emuStatus = if (payload.deviceData.isEmulator) "🟡 Emulator" else "🟢 Physical Device"
                tvSummaryRoot.text = "• Device / Security: $rootStatus | $mockStatus | $emuStatus"

                // Update App Detection Detailed Breakdown
                cardAppDetectionResults.visibility = View.VISIBLE
                tvAppDetectionSubtitle.text = "${payload.installedApps.totalDetected} of ${payload.installedApps.totalTargetsScanned} targets found on device (${payload.installedApps.riskLevel})"

                val detectedPackageSet = payload.installedApps.detectedApps.map { it.detectionIdentifier }.toSet()
                val breakdownText = if (targetsToScan.isEmpty()) {
                    "No target apps specified for scan."
                } else {
                    targetsToScan.joinToString("\n\n") { target ->
                        val isFound = detectedPackageSet.contains(target.packageName)
                        val badge = if (isFound) "🔴 [INSTALLED]" else "⚪ [NOT INSTALLED]"
                        "$badge ${target.name}\n  └─ Package: ${target.packageName}\n  └─ Category: ${target.category}"
                    }
                }
                tvAppDetectionList.text = breakdownText

                // Show raw JSON & copy button
                tvResult.text = jsonResult
                btnCopyJson.visibility = View.VISIBLE

            } catch (e: Exception) {
                Log.e("SentinelSDK", "Error during capture", e)
                tvResult.text = "Error executing capture: ${e.localizedMessage}"
            } finally {
                progressBar.visibility = View.GONE
                btnCapture.isEnabled = true
            }
        }
    }
}
