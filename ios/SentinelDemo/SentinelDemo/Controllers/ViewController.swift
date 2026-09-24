import UIKit
import CoreLocation
import SentinelSDK

/// iOS Native Demo ViewController mirroring the Android Sample App for testing and verification.
public class ViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {

    // MARK: - Color Palette
    private let colorBackground = UIColor(red: 9/255, green: 13/255, blue: 22/255, alpha: 1.0)       // #090D16
    private let colorCardBg = UIColor(red: 19/255, green: 27/255, blue: 46/255, alpha: 1.0)          // #131B2E
    private let colorBorder = UIColor(red: 30/255, green: 41/255, blue: 59/255, alpha: 1.0)          // #1E293B
    private let colorAccent = UIColor(red: 59/255, green: 130/255, blue: 246/255, alpha: 1.0)        // #3B82F6
    private let colorAccentDark = UIColor(red: 29/255, green: 78/255, blue: 216/255, alpha: 1.0)    // #1D4ED8
    private let colorTextPrimary = UIColor(red: 248/255, green: 250/255, blue: 252/255, alpha: 1.0) // #F8FAFC
    private let colorTextSecondary = UIColor(red: 148/255, green: 163/255, blue: 184/255, alpha: 1.0) // #94A3B8
    private let colorSuccess = UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1.0)       // #10B981
    private let colorDanger = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)         // #EF4444

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Header
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // User Inputs
    private let inputCardView = UIView()
    private let sectionTitleLabel = UILabel()
    private let fullNameField = UITextField()
    private let documentIdField = UITextField()
    private let emailField = UITextField()
    private let phoneNumberField = UITextField()

    // Preset Buttons
    private let validPresetButton = UIButton(type: .system)
    private let invalidPresetButton = UIButton(type: .system)

    // Action Button & Spinner
    private let captureButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    // Telemetry & Risk Summary Card
    private let summaryCardView = UIView()
    private let summaryTitleLabel = UILabel()
    private let summaryRiskLabel = UILabel()
    private let summaryUserValidLabel = UILabel()
    private let summaryLocationLabel = UILabel()
    private let summaryDeviceLabel = UILabel()

    // Result Section
    private let resultHeaderView = UIView()
    private let resultSectionLabel = UILabel()
    private let copyJsonButton = UIButton(type: .system)
    private let shareJsonButton = UIButton(type: .system)
    private let resultCardView = UIView()
    private let resultTextView = UITextView()

    // Toast HUD
    private let toastLabel = UILabel()

    // Location Manager
    private let locationManager = CLLocationManager()
    private var lastJsonOutput: String?

    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = colorBackground
        locationManager.delegate = self

        // 1. Initialize Sentinel SDK
        SentinelSDK.shared.initialize(
            apiKey: "test_enterprise_api_key_12345",
            environment: "sandbox"
        )

        setupUI()
        setupListeners()
        setupKeyboardDismissal()
    }

    // MARK: - UI Setup
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // 1. Header
        titleLabel.text = "🛡️ Sentinel SDK"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = colorTextPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.text = "iOS Live Verification & Risk Screening"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = colorTextSecondary
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])

        // 2. User Input Card
        setupInputCard()

        // 3. Main Action Button & Progress Indicator
        setupActionButton()

        // 4. Telemetry Summary Card
        setupSummaryCard()

        // 5. Raw JSON Payload Section
        setupResultSection()

        // 6. Toast Feedback View
        setupToast()
    }

    private func setupInputCard() {
        styleCard(inputCardView)
        inputCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(inputCardView)

        sectionTitleLabel.text = "USER IDENTITY ATTRIBUTES"
        sectionTitleLabel.font = .systemFont(ofSize: 12, weight: .bold)
        sectionTitleLabel.textColor = colorAccent
        sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        inputCardView.addSubview(sectionTitleLabel)

        configureTextField(fullNameField, placeholder: "Full Name", text: "Carlos Eduardo da Silva")
        configureTextField(documentIdField, placeholder: "Document ID (CPF / CNPJ)", text: "123.456.789-09")
        configureTextField(emailField, placeholder: "Email Address", text: "carlos.silva@example.com", keyboardType: .emailAddress)
        configureTextField(phoneNumberField, placeholder: "Phone Number (E.164)", text: "+5511999998888", keyboardType: .phonePad)

        // Presets Container
        let presetStack = UIStackView(arrangedSubviews: [validPresetButton, invalidPresetButton])
        presetStack.axis = .horizontal
        presetStack.spacing = 10
        presetStack.distribution = .fillEqually
        presetStack.translatesAutoresizingMaskIntoConstraints = false

        styleOutlinedButton(validPresetButton, title: "Valid Preset", color: colorSuccess)
        styleOutlinedButton(invalidPresetButton, title: "Invalid Preset", color: colorDanger)

        [fullNameField, documentIdField, emailField, phoneNumberField, presetStack].forEach {
            inputCardView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            inputCardView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            inputCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            inputCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            sectionTitleLabel.topAnchor.constraint(equalTo: inputCardView.topAnchor, constant: 16),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: inputCardView.leadingAnchor, constant: 16),
            sectionTitleLabel.trailingAnchor.constraint(equalTo: inputCardView.trailingAnchor, constant: -16),

            fullNameField.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 12),
            fullNameField.leadingAnchor.constraint(equalTo: inputCardView.leadingAnchor, constant: 16),
            fullNameField.trailingAnchor.constraint(equalTo: inputCardView.trailingAnchor, constant: -16),
            fullNameField.heightAnchor.constraint(equalToConstant: 44),

            documentIdField.topAnchor.constraint(equalTo: fullNameField.bottomAnchor, constant: 10),
            documentIdField.leadingAnchor.constraint(equalTo: inputCardView.leadingAnchor, constant: 16),
            documentIdField.trailingAnchor.constraint(equalTo: inputCardView.trailingAnchor, constant: -16),
            documentIdField.heightAnchor.constraint(equalToConstant: 44),

            emailField.topAnchor.constraint(equalTo: documentIdField.bottomAnchor, constant: 10),
            emailField.leadingAnchor.constraint(equalTo: inputCardView.leadingAnchor, constant: 16),
            emailField.trailingAnchor.constraint(equalTo: inputCardView.trailingAnchor, constant: -16),
            emailField.heightAnchor.constraint(equalToConstant: 44),

            phoneNumberField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 10),
            phoneNumberField.leadingAnchor.constraint(equalTo: inputCardView.leadingAnchor, constant: 16),
            phoneNumberField.trailingAnchor.constraint(equalTo: inputCardView.trailingAnchor, constant: -16),
            phoneNumberField.heightAnchor.constraint(equalToConstant: 44),

            presetStack.topAnchor.constraint(equalTo: phoneNumberField.bottomAnchor, constant: 12),
            presetStack.leadingAnchor.constraint(equalTo: inputCardView.leadingAnchor, constant: 16),
            presetStack.trailingAnchor.constraint(equalTo: inputCardView.trailingAnchor, constant: -16),
            presetStack.heightAnchor.constraint(equalToConstant: 40),
            presetStack.bottomAnchor.constraint(equalTo: inputCardView.bottomAnchor, constant: -16)
        ])
    }

    private func setupActionButton() {
        captureButton.setTitle("Run Sentinel Capture", for: .normal)
        captureButton.setTitleColor(colorTextPrimary, for: .normal)
        captureButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        captureButton.backgroundColor = colorAccent
        captureButton.layer.cornerRadius = 12
        captureButton.translatesAutoresizingMaskIntoConstraints = false

        activityIndicator.color = colorAccent
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(captureButton)
        contentView.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            captureButton.topAnchor.constraint(equalTo: inputCardView.bottomAnchor, constant: 16),
            captureButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            captureButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            captureButton.heightAnchor.constraint(equalToConstant: 54),

            activityIndicator.topAnchor.constraint(equalTo: captureButton.bottomAnchor, constant: 8),
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }

    private func setupSummaryCard() {
        styleCard(summaryCardView)
        summaryCardView.isHidden = true
        summaryCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(summaryCardView)

        summaryTitleLabel.text = "TELEMETRY & RISK SUMMARY"
        summaryTitleLabel.font = .systemFont(ofSize: 12, weight: .bold)
        summaryTitleLabel.textColor = colorAccent
        summaryTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        [summaryRiskLabel, summaryUserValidLabel, summaryLocationLabel, summaryDeviceLabel].forEach {
            $0.font = .systemFont(ofSize: 13, weight: .medium)
            $0.textColor = colorTextPrimary
            $0.numberOfLines = 0
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        summaryRiskLabel.text = "• Risk Level: -"
        summaryUserValidLabel.text = "• User Identity: -"
        summaryLocationLabel.text = "• Location Status: -"
        summaryDeviceLabel.text = "• Root / Spoof: -"

        [summaryTitleLabel, summaryRiskLabel, summaryUserValidLabel, summaryLocationLabel, summaryDeviceLabel].forEach {
            summaryCardView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            summaryCardView.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 8),
            summaryCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            summaryCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            summaryTitleLabel.topAnchor.constraint(equalTo: summaryCardView.topAnchor, constant: 16),
            summaryTitleLabel.leadingAnchor.constraint(equalTo: summaryCardView.leadingAnchor, constant: 16),
            summaryTitleLabel.trailingAnchor.constraint(equalTo: summaryCardView.trailingAnchor, constant: -16),

            summaryRiskLabel.topAnchor.constraint(equalTo: summaryTitleLabel.bottomAnchor, constant: 8),
            summaryRiskLabel.leadingAnchor.constraint(equalTo: summaryCardView.leadingAnchor, constant: 16),
            summaryRiskLabel.trailingAnchor.constraint(equalTo: summaryCardView.trailingAnchor, constant: -16),

            summaryUserValidLabel.topAnchor.constraint(equalTo: summaryRiskLabel.bottomAnchor, constant: 6),
            summaryUserValidLabel.leadingAnchor.constraint(equalTo: summaryCardView.leadingAnchor, constant: 16),
            summaryUserValidLabel.trailingAnchor.constraint(equalTo: summaryCardView.trailingAnchor, constant: -16),

            summaryLocationLabel.topAnchor.constraint(equalTo: summaryUserValidLabel.bottomAnchor, constant: 6),
            summaryLocationLabel.leadingAnchor.constraint(equalTo: summaryCardView.leadingAnchor, constant: 16),
            summaryLocationLabel.trailingAnchor.constraint(equalTo: summaryCardView.trailingAnchor, constant: -16),

            summaryDeviceLabel.topAnchor.constraint(equalTo: summaryLocationLabel.bottomAnchor, constant: 6),
            summaryDeviceLabel.leadingAnchor.constraint(equalTo: summaryCardView.leadingAnchor, constant: 16),
            summaryDeviceLabel.trailingAnchor.constraint(equalTo: summaryCardView.trailingAnchor, constant: -16),
            summaryDeviceLabel.bottomAnchor.constraint(equalTo: summaryCardView.bottomAnchor, constant: -16)
        ])
    }

    private func setupResultSection() {
        resultHeaderView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(resultHeaderView)

        resultSectionLabel.text = "Full Normalized Payload"
        resultSectionLabel.font = .systemFont(ofSize: 14, weight: .bold)
        resultSectionLabel.textColor = colorTextSecondary
        resultSectionLabel.translatesAutoresizingMaskIntoConstraints = false

        copyJsonButton.setTitle("Copy JSON", for: .normal)
        copyJsonButton.setTitleColor(colorAccent, for: .normal)
        copyJsonButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        copyJsonButton.isHidden = true
        copyJsonButton.translatesAutoresizingMaskIntoConstraints = false

        shareJsonButton.setTitle("Share", for: .normal)
        shareJsonButton.setTitleColor(colorAccent, for: .normal)
        shareJsonButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        shareJsonButton.isHidden = true
        shareJsonButton.translatesAutoresizingMaskIntoConstraints = false

        resultHeaderView.addSubview(resultSectionLabel)
        resultHeaderView.addSubview(shareJsonButton)
        resultHeaderView.addSubview(copyJsonButton)

        styleCard(resultCardView)
        resultCardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(resultCardView)

        resultTextView.text = "Tap 'Run Sentinel Capture' above to inspect live device telemetry and risk screening..."
        resultTextView.textColor = colorTextSecondary
        resultTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        resultTextView.backgroundColor = .clear
        resultTextView.isEditable = false
        resultTextView.isScrollEnabled = false
        resultTextView.translatesAutoresizingMaskIntoConstraints = false
        resultCardView.addSubview(resultTextView)

        NSLayoutConstraint.activate([
            resultHeaderView.topAnchor.constraint(equalTo: summaryCardView.bottomAnchor, constant: 16),
            resultHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            resultHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            resultHeaderView.heightAnchor.constraint(equalToConstant: 30),

            resultSectionLabel.leadingAnchor.constraint(equalTo: resultHeaderView.leadingAnchor),
            resultSectionLabel.centerYAnchor.constraint(equalTo: resultHeaderView.centerYAnchor),

            shareJsonButton.trailingAnchor.constraint(equalTo: resultHeaderView.trailingAnchor),
            shareJsonButton.centerYAnchor.constraint(equalTo: resultHeaderView.centerYAnchor),

            copyJsonButton.trailingAnchor.constraint(equalTo: shareJsonButton.leadingAnchor, constant: -12),
            copyJsonButton.centerYAnchor.constraint(equalTo: resultHeaderView.centerYAnchor),

            resultCardView.topAnchor.constraint(equalTo: resultHeaderView.bottomAnchor, constant: 8),
            resultCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            resultCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            resultCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),

            resultTextView.topAnchor.constraint(equalTo: resultCardView.topAnchor, constant: 12),
            resultTextView.leadingAnchor.constraint(equalTo: resultCardView.leadingAnchor, constant: 12),
            resultTextView.trailingAnchor.constraint(equalTo: resultCardView.trailingAnchor, constant: -12),
            resultTextView.bottomAnchor.constraint(equalTo: resultCardView.bottomAnchor, constant: -12)
        ])
    }

    private func setupToast() {
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        toastLabel.textColor = .white
        toastLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        toastLabel.textAlignment = .center
        toastLabel.layer.cornerRadius = 18
        toastLabel.clipsToBounds = true
        toastLabel.alpha = 0.0
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toastLabel)

        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            toastLabel.heightAnchor.constraint(equalToConstant: 36),
            toastLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 180)
        ])
    }

    // MARK: - View Styling Helpers
    private func styleCard(_ card: UIView) {
        card.backgroundColor = colorCardBg
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = colorBorder.cgColor
    }

    private func configureTextField(_ textField: UITextField, placeholder: String, text: String, keyboardType: UIKeyboardType = .default) {
        textField.text = text
        textField.font = .systemFont(ofSize: 14)
        textField.textColor = colorTextPrimary
        textField.backgroundColor = colorBackground
        textField.layer.cornerRadius = 8
        textField.layer.borderWidth = 1
        textField.layer.borderColor = colorBorder.cgColor
        textField.keyboardType = keyboardType
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false

        // Padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        textField.leftView = paddingView
        textField.leftViewMode = .always

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: colorTextSecondary]
        )
    }

    private func styleOutlinedButton(_ button: UIButton, title: String, color: UIColor) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = color.cgColor
    }

    // MARK: - Listeners & Actions
    private func setupListeners() {
        validPresetButton.addTarget(self, action: #selector(handleValidPreset), for: .touchUpInside)
        invalidPresetButton.addTarget(self, action: #selector(handleInvalidPreset), for: .touchUpInside)
        captureButton.addTarget(self, action: #selector(handleCaptureTap), for: .touchUpInside)
        copyJsonButton.addTarget(self, action: #selector(handleCopyJson), for: .touchUpInside)
        shareJsonButton.addTarget(self, action: #selector(handleShareJson), for: .touchUpInside)
    }

    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc private func handleValidPreset() {
        fullNameField.text = "Carlos Eduardo da Silva"
        documentIdField.text = "123.456.789-09"
        emailField.text = "carlos.silva@example.com"
        phoneNumberField.text = "+5511999998888"
        showToast("Loaded Valid Preset")
    }

    @objc private func handleInvalidPreset() {
        fullNameField.text = "Carlos"
        documentIdField.text = "111.111.111-11"
        emailField.text = "invalid-email-address"
        phoneNumberField.text = "1234"
        showToast("Loaded Invalid Preset")
    }

    @objc private func handleCaptureTap() {
        dismissKeyboard()

        // Check location permission
        let authStatus: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            authStatus = locationManager.authorizationStatus
        } else {
            authStatus = CLLocationManager.authorizationStatus()
        }

        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else {
            executeCapture()
        }
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        if status != .notDetermined {
            executeCapture()
        }
    }

    // MARK: - SDK Capture Execution
    private func executeCapture() {
        guard captureButton.isEnabled else { return }

        activityIndicator.startAnimating()
        captureButton.isEnabled = false
        captureButton.alpha = 0.7

        let input = PersonalDataValidator.Input(
            fullName: fullNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            documentId: documentIdField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            email: emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phoneNumberField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        let config = SentinelSDK.CaptureConfiguration(
            userData: input,
            locationTimeoutSeconds: 5.0,
            wrapper: "native_ios_demo"
        )

        Task {
            let payload = await SentinelSDK.shared.capture(configuration: config)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = (try? encoder.encode(payload)) ?? Data()
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

            await MainActor.run {
                self.activityIndicator.stopAnimating()
                self.captureButton.isEnabled = true
                self.captureButton.alpha = 1.0

                self.lastJsonOutput = jsonString

                // Update Summary Badges
                self.summaryCardView.isHidden = false
                let riskEmoji = payload.installedApps.riskLevel == "CLEAN" ? "🟢 CLEAN" : "🔴 FLAGGED (\(payload.installedApps.totalDetected) apps)"
                self.summaryRiskLabel.text = "• Risk Level: \(riskEmoji)"

                let userValid = payload.userData.validation.isValid
                let userEmoji = userValid ? "🟢 Valid" : "🔴 Invalid (\(payload.userData.validation.validationErrors.joined(separator: ", ")))"
                self.summaryUserValidLabel.text = "• User Identity: \(userEmoji)"

                let locStatus = payload.locationData.status
                let locEmoji = locStatus == "SUCCESS"
                    ? String(format: "🟢 GPS Lock (%.4f, %.4f)", payload.locationData.coordinates.latitude, payload.locationData.coordinates.longitude)
                    : "🟡 \(locStatus)"
                self.summaryLocationLabel.text = "• Location: \(locEmoji)"

                let rootStatus = payload.deviceData.isJailbrokenOrRooted ? "🔴 JAILBROKEN" : "🟢 Unrooted"
                let mockStatus = payload.locationData.isMockLocation ? "🔴 MOCK GPS" : "🟢 Real GPS"
                let emuStatus = payload.deviceData.isEmulator ? "🟡 Simulator" : "🟢 Physical Device"
                self.summaryDeviceLabel.text = "• Device / Security: \(rootStatus) | \(mockStatus) | \(emuStatus)"

                // Show formatted JSON result
                self.resultTextView.text = jsonString
                self.resultTextView.textColor = self.colorTextPrimary
                self.copyJsonButton.isHidden = false
                self.shareJsonButton.isHidden = false
            }
        }
    }

    @objc private func handleCopyJson() {
        guard let json = lastJsonOutput else { return }
        UIPasteboard.general.string = json
        showToast("JSON copied to clipboard")
    }

    @objc private func handleShareJson() {
        guard let json = lastJsonOutput else { return }
        let activityVC = UIActivityViewController(activityItems: [json], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareJsonButton
            popover.sourceRect = shareJsonButton.bounds
        }
        present(activityVC, animated: true)
    }

    private func showToast(_ message: String) {
        toastLabel.text = "   \(message)   "
        UIView.animate(withDuration: 0.3, animations: {
            self.toastLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseOut, animations: {
                self.toastLabel.alpha = 0.0
            }, completion: nil)
        }
    }
}
