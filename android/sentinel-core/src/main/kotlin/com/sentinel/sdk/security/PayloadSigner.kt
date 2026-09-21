package com.sentinel.sdk.security

import com.sentinel.sdk.models.SentinelSecurityData
import java.security.MessageDigest
import java.util.UUID
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

class PayloadSigner(private val secretKey: String? = null) {

    fun sign(payloadJson: String, nonce: String = UUID.randomUUID().toString()): SentinelSecurityData {
        val payloadHash = sha256Hex(payloadJson.toByteArray(Charsets.UTF_8))
        val signature = generateSignature(payloadHash, nonce)

        return SentinelSecurityData(
            payloadHash = payloadHash,
            signature = signature,
            nonce = nonce,
            tamperDetected = false
        )
    }

    fun sha256Hex(bytes: ByteArray): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(bytes)
        return digest.joinToString("") { "%02x".format(it) }
    }

    fun generateSignature(payloadHash: String, nonce: String): String {
        val message = "$payloadHash:$nonce"
        val messageBytes = message.toByteArray(Charsets.UTF_8)

        return if (!secretKey.isNullOrEmpty()) {
            val keySpec = SecretKeySpec(secretKey.toByteArray(Charsets.UTF_8), "HmacSHA256")
            val mac = Mac.getInstance("HmacSHA256")
            mac.init(keySpec)
            val hmacBytes = mac.doFinal(messageBytes)
            java.util.Base64.getEncoder().encodeToString(hmacBytes)
        } else {
            val digest = MessageDigest.getInstance("SHA-256").digest(messageBytes)
            java.util.Base64.getEncoder().encodeToString(digest)
        }
    }

    fun verify(payloadHash: String, nonce: String, signature: String): Boolean {
        val expected = generateSignature(payloadHash, nonce)
        return expected == signature
    }
}
