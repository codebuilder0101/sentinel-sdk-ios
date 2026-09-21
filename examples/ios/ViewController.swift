import UIKit
import SentinelSDK

class ViewController: UIViewController {

    private let statusLabel = UILabel()
    private let captureButton = UIButton(type: .system)
    private let resultTextView = UITextView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()

        // 1. Initialize Sentinel SDK
        SentinelSDK.shared.initialize(apiKey: "test_client_api_key_12345", environment: "production")
    }

    private func setupUI() {
        title = "Sentinel iOS Native Demo"

        captureButton.setTitle("Run Sentinel Capture", for: .normal)
        captureButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        captureButton.backgroundColor = .systemBlue
        captureButton.setTitleColor(.white, for: .normal)
        captureButton.layer.cornerRadius = 8
        captureButton.addTarget(self, action: #selector(handleCapture), for: .touchUpInside)

        resultTextView.isEditable = false
        resultTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        resultTextView.backgroundColor = .secondarySystemBackground
        resultTextView.layer.cornerRadius = 8

        [captureButton, activityIndicator, resultTextView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            captureButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            captureButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            captureButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            captureButton.heightAnchor.constraint(equalToConstant: 50),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            resultTextView.topAnchor.constraint(equalTo: captureButton.bottomAnchor, constant: 20),
            resultTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resultTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    @objc private func handleCapture() {
        activityIndicator.startAnimating()
        captureButton.isEnabled = false

        let input = PersonalDataValidator.Input(
            fullName: "Carlos Eduardo da Silva",
            documentId: "123.456.789-09",
            email: "carlos.silva@example.com",
            phoneNumber: "+5511999998888"
        )

        let config = SentinelSDK.CaptureConfiguration(
            userData: input,
            locationTimeoutSeconds: 5.0,
            wrapper: "native"
        )

        Task {
            do {
                let json = try await SentinelSDK.shared.captureJSON(configuration: config)
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.captureButton.isEnabled = true
                    self.resultTextView.text = json
                }
            } catch {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.captureButton.isEnabled = true
                    self.resultTextView.text = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
