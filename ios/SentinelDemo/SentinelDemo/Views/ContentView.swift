import SwiftUI
import CoreLocation
import SentinelSDK

/// Modern SwiftUI Testing & Verification View mirroring the Android Sample App.
public struct ContentView: View {

    // MARK: - State Properties
    @State private var fullName: String = "Carlos Eduardo da Silva"
    @State private var documentId: String = "123.456.789-09"
    @State private var email: String = "carlos.silva@example.com"
    @State private var phoneNumber: String = "+5511999998888"

    @State private var isCapturing: Bool = false
    @State private var capturedPayload: SentinelPayload? = nil
    @State private var rawJsonString: String = ""
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var showShareSheet: Bool = false

    @StateObject private var locationHelper = LocationPermissionHelper()

    // Color Palette
    private let bgDark = Color(red: 9/255, green: 13/255, blue: 22/255)
    private let cardBg = Color(red: 19/255, green: 27/255, blue: 46/255)
    private let borderDark = Color(red: 30/255, green: 41/255, blue: 59/255)
    private let accentBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
    private let successGreen = Color(red: 16/255, green: 185/255, blue: 129/255)
    private let dangerRed = Color(red: 239/255, green: 68/255, blue: 68/255)
    private let textPrimary = Color(red: 248/255, green: 250/255, blue: 252/255)
    private let textSecondary = Color(red: 148/255, green: 163/255, blue: 184/255)

    public init() {}

    public var body: some View {
        ZStack {
            bgDark.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 1. Header
                    headerView

                    // 2. User Identity Attributes Card
                    inputCardView

                    // 3. Action Button
                    actionButtonView

                    // 4. Telemetry & Risk Summary Card
                    if let payload = capturedPayload {
                        summaryCardView(payload: payload)
                    }

                    // 5. Normalized JSON Output Box
                    jsonOutputCardView
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            // Toast HUD
            if showToast {
                VStack {
                    Spacer()
                    Text(toastMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [rawJsonString])
        }
        .onAppear {
            SentinelSDK.shared.initialize(
                apiKey: "test_enterprise_api_key_12345",
                environment: "sandbox"
            )
        }
    }

    // MARK: - Subviews
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🛡️ Sentinel SDK")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(textPrimary)

            Text("iOS Live Verification & Risk Screening")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textSecondary)
        }
    }

    private var inputCardView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("USER IDENTITY ATTRIBUTES")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(accentBlue)

            CustomTextField(title: "Full Name", text: $fullName)
            CustomTextField(title: "Document ID (CPF / CNPJ)", text: $documentId)
            CustomTextField(title: "Email Address", text: $email, keyboardType: .emailAddress)
            CustomTextField(title: "Phone Number (E.164)", text: $phoneNumber, keyboardType: .phonePad)

            HStack(spacing: 10) {
                Button(action: loadValidPreset) {
                    Text("Valid Preset")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(successGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(successGreen, lineWidth: 1)
                        )
                }

                Button(action: loadInvalidPreset) {
                    Text("Invalid Preset")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(dangerRed)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(dangerRed, lineWidth: 1)
                        )
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderDark, lineWidth: 1)
        )
    }

    private var actionButtonView: some View {
        VStack(spacing: 8) {
            Button(action: runCapture) {
                HStack(spacing: 10) {
                    if isCapturing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isCapturing ? "Scanning Telemetry..." : "Run Sentinel Capture")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(isCapturing ? accentBlue.opacity(0.6) : accentBlue)
                .cornerRadius(12)
            }
            .disabled(isCapturing)
        }
    }

    private func summaryCardView(payload: SentinelPayload) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TELEMETRY & RISK SUMMARY")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(accentBlue)

            let riskEmoji = payload.installedApps.riskLevel == "CLEAN" ? "🟢 CLEAN" : "🔴 FLAGGED (\(payload.installedApps.totalDetected) apps)"
            Text("• Risk Level: \(riskEmoji)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textPrimary)

            let userValid = payload.userData.validation.isValid
            let userEmoji = userValid ? "🟢 Valid" : "🔴 Invalid (\(payload.userData.validation.validationErrors.joined(separator: ", ")))"
            Text("• User Identity: \(userEmoji)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textPrimary)

            let locStatus = payload.locationData.status
            let locEmoji = locStatus == "SUCCESS"
                ? String(format: "🟢 GPS Lock (%.4f, %.4f)", payload.locationData.coordinates.latitude, payload.locationData.coordinates.longitude)
                : "🟡 \(locStatus)"
            Text("• Location: \(locEmoji)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textPrimary)

            let rootStatus = payload.deviceData.isJailbrokenOrRooted ? "🔴 JAILBROKEN" : "🟢 Unrooted"
            let mockStatus = payload.locationData.isMockLocation ? "🔴 MOCK GPS" : "🟢 Real GPS"
            let emuStatus = payload.deviceData.isEmulator ? "🟡 Simulator" : "🟢 Physical Device"
            Text("• Device / Security: \(rootStatus) | \(mockStatus) | \(emuStatus)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderDark, lineWidth: 1)
        )
    }

    private var jsonOutputCardView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Full Normalized Payload")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(textSecondary)

                Spacer()

                if !rawJsonString.isEmpty {
                    Button(action: copyToClipboard) {
                        Text("Copy JSON")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(accentBlue)
                    }
                    .padding(.trailing, 8)

                    Button(action: { showShareSheet = true }) {
                        Text("Share")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(accentBlue)
                    }
                }
            }

            Text(rawJsonString.isEmpty ? "Tap 'Run Sentinel Capture' above to inspect live device telemetry and risk screening..." : rawJsonString)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(rawJsonString.isEmpty ? textSecondary : textPrimary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBg)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderDark, lineWidth: 1)
                )
        }
        .padding(.bottom, 24)
    }

    // MARK: - Actions
    private func loadValidPreset() {
        fullName = "Carlos Eduardo da Silva"
        documentId = "123.456.789-09"
        email = "carlos.silva@example.com"
        phoneNumber = "+5511999998888"
        displayToast("Loaded Valid Preset")
    }

    private func loadInvalidPreset() {
        fullName = "Carlos"
        documentId = "111.111.111-11"
        email = "invalid-email-address"
        phoneNumber = "1234"
        displayToast("Loaded Invalid Preset")
    }

    private func runCapture() {
        locationHelper.requestPermissionIfNeeded()
        isCapturing = true

        let input = PersonalDataValidator.Input(
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            documentId: documentId.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        let config = SentinelSDK.CaptureConfiguration(
            userData: input,
            locationTimeoutSeconds: 5.0,
            wrapper: "swiftui_demo"
        )

        Task {
            let payload = await SentinelSDK.shared.capture(configuration: config)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = (try? encoder.encode(payload)) ?? Data()
            let jsonString = String(data: data, encoding: .utf8) ?? "{}"

            await MainActor.run {
                self.capturedPayload = payload
                self.rawJsonString = jsonString
                self.isCapturing = false
            }
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = rawJsonString
        displayToast("JSON copied to clipboard")
    }

    private func displayToast(_ msg: String) {
        toastMessage = msg
        withAnimation(.easeInOut(duration: 0.2)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showToast = false
            }
        }
    }
}

// MARK: - Custom Helper Views
private struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    private let bgDark = Color(red: 9/255, green: 13/255, blue: 22/255)
    private let borderDark = Color(red: 30/255, green: 41/255, blue: 59/255)
    private let textPrimary = Color(red: 248/255, green: 250/255, blue: 252/255)
    private let textSecondary = Color(red: 148/255, green: 163/255, blue: 184/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(textSecondary)

            TextField(title, text: $text)
                .font(.system(size: 14))
                .foregroundColor(textPrimary)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(bgDark)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderDark, lineWidth: 1)
                )
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private final class LocationPermissionHelper: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestPermissionIfNeeded() {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
}
