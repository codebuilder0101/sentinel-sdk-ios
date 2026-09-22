package com.sentinel.sdk.security

import com.sentinel.sdk.models.SentinelSecurityData
import java.security.MessageDigest
import java.util.UUID
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi

class PayloadSigner(private val secretKey: String? = null) {

    fun sign(
        payloadJson: String,
        nonce: String = UUID.randomUUID().toString(),
        tamperDetected: Boolean = false
    ): SentinelSecurityData {
        val payloadHash = sha256Hex(payloadJson.toByteArray(Charsets.UTF_8))
        val signature = generateSignature(payloadHash, nonce)

        return SentinelSecurityData(
            payloadHash = payloadHash,
            signature = signature,
            nonce = nonce,
            tamperDetected = tamperDetected
        )
    }

    fun sha256Hex(bytes: ByteArray): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(bytes)
        return digest.joinToString("") { "%02x".format(it) }
    }

    @OptIn(ExperimentalEncodingApi::class)
    fun generateSignature(payloadHash: String, nonce: String): String {
        val message = "$payloadHash:$nonce"
        val messageBytes = message.toByteArray(Charsets.UTF_8)

        return if (!secretKey.isNullOrEmpty()) {
            val keySpec = SecretKeySpec(secretKey.toByteArray(Charsets.UTF_8), "HmacSHA256")
            val mac = Mac.getInstance("HmacSHA256")
            mac.init(keySpec)
            val hmacBytes = mac.doFinal(messageBytes)
            Base64.encode(hmacBytes)
        } else {
            val digest = MessageDigest.getInstance("SHA-256").digest(messageBytes)
            Base64.encode(digest)
        }
    }

    fun verify(payloadHash: String, nonce: String, signature: String): Boolean {
        val expected = generateSignature(payloadHash, nonce)
        val expectedBytes = expected.toByteArray(Charsets.UTF_8)
        val signatureBytes = signature.toByteArray(Charsets.UTF_8)
        return MessageDigest.isEqual(expectedBytes, signatureBytes)
    }
}


