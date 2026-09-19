import Foundation

/// Security metadata, payload hash, and cryptographic signature.
public struct SentinelSecurityData: Codable {
    public let payloadHash: String
    public let signature: String
    public let nonce: String
    public let tamperDetected: Bool

    enum CodingKeys: String, CodingKey {
        case payloadHash = "payload_hash"
        case signature
        case nonce
        case tamperDetected = "tamper_detected"
    }

    public init(
        payloadHash: String,
        signature: String,
        nonce: String,
        tamperDetected: Bool = false
    ) {
        self.payloadHash = payloadHash
        self.signature = signature
        self.nonce = nonce
        self.tamperDetected = tamperDetected
    }
}
