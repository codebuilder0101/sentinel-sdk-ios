import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Generates cryptographic checksums and signatures for captured payloads.
public final class PayloadSigner {

    private let secretKey: String?

    public init(secretKey: String? = nil) {
        self.secretKey = secretKey
    }

    public func sign(data: Data, nonce: String = UUID().uuidString) -> SentinelSecurityData {
        let hashString = sha256Hex(data: data)
        let signature = generateSignature(payloadHash: hashString, nonce: nonce)

        return SentinelSecurityData(
            payloadHash: hashString,
            signature: signature,
            nonce: nonce,
            tamperDetected: false
        )
    }

    public func sha256Hex(data: Data) -> String {
        #if canImport(CryptoKit)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02hhx", $0) }.joined()
        #else
        return "\(data.count)"
        #endif
    }

    public func generateSignature(payloadHash: String, nonce: String) -> String {
        let message = "\(payloadHash):\(nonce)"
        guard let messageData = message.data(using: .utf8) else { return "" }

        #if canImport(CryptoKit)
        if let key = secretKey, !key.isEmpty, let keyData = key.data(using: .utf8) {
            let symmetricKey = SymmetricKey(data: keyData)
            let mac = HMAC<SHA256>.authenticationCode(for: messageData, using: symmetricKey)
            return Data(mac).base64EncodedString()
        } else {
            let digest = SHA256.hash(data: messageData)
            return Data(digest).base64EncodedString()
        }
        #else
        return messageData.base64EncodedString()
        #endif
    }

    public func verify(payloadHash: String, nonce: String, signature: String) -> Bool {
        let expected = generateSignature(payloadHash: payloadHash, nonce: nonce)
        return expected == signature
    }
}
