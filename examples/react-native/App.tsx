import React, { useState, useEffect } from 'react';
import {
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
  TextInput,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { SentinelSDK, CapturePayload } from '@sentinel/react-native';

export default function App() {
  const [fullName, setFullName] = useState('João da Silva');
  const [documentId, setDocumentId] = useState('123.456.789-09');
  const [email, setEmail] = useState('joao.silva@example.com');
  const [phone, setPhone] = useState('+5511999998888');
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<CapturePayload | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Initialize Sentinel SDK with client API credentials
    SentinelSDK.initialize({
      apiKey: 'test_client_api_key_12345',
      environment: 'production',
    }).catch((err) => {
      console.error('Initialization error:', err);
    });
  }, []);

  const handleCapture = async () => {
    setLoading(true);
    setError(null);
    try {
      const payload = await SentinelSDK.capture({
        userData: {
          fullName,
          documentId,
          email,
          phoneNumber: phone,
        },
        timeoutMs: 8000,
      });
      setResult(payload);
    } catch (err: any) {
      setError(err?.message || 'Capture failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.title}>Sentinel Security SDK</Text>
        <Text style={styles.subtitle}>Mobile Identity & Risk Verification</Text>

        <View style={styles.card}>
          <Text style={styles.label}>Full Name</Text>
          <TextInput style={styles.input} value={fullName} onChangeText={setFullName} />

          <Text style={styles.label}>CPF / Document ID</Text>
          <TextInput style={styles.input} value={documentId} onChangeText={setDocumentId} />

          <Text style={styles.label}>Email Address</Text>
          <TextInput style={styles.input} value={email} onChangeText={setEmail} autoCapitalize="none" />

          <Text style={styles.label}>Mobile Phone Number</Text>
          <TextInput style={styles.input} value={phone} onChangeText={setPhone} />

          <TouchableOpacity
            style={[styles.button, loading && styles.buttonDisabled]}
            onPress={handleCapture}
            disabled={loading}
          >
            {loading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.buttonText}>Run Sentinel Capture</Text>
            )}
          </TouchableOpacity>
        </View>

        {error && (
          <View style={styles.errorBox}>
            <Text style={styles.errorText}>{error}</Text>
          </View>
        )}

        {result && (
          <View style={styles.resultCard}>
            <Text style={styles.resultTitle}>Capture Result:</Text>
            <Text style={styles.jsonText}>{JSON.stringify(result, null, 2)}</Text>
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f8fafc' },
  scroll: { padding: 20 },
  title: { fontSize: 24, fontWeight: '800', color: '#0f172a', marginBottom: 4 },
  subtitle: { fontSize: 14, color: '#2563eb', fontWeight: '600', marginBottom: 20 },
  card: {
    backgroundColor: '#ffffff',
    borderRadius: 12,
    padding: 18,
    borderWidth: 1,
    borderColor: '#e2e8f0',
    marginBottom: 20,
  },
  label: { fontSize: 12, fontWeight: '700', color: '#64748b', marginBottom: 6 },
  input: {
    borderWidth: 1,
    borderColor: '#cbd5e1',
    borderRadius: 8,
    padding: 12,
    fontSize: 14,
    marginBottom: 14,
    color: '#0f172a',
  },
  button: {
    backgroundColor: '#2563eb',
    borderRadius: 8,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 6,
  },
  buttonDisabled: { opacity: 0.6 },
  buttonText: { color: '#ffffff', fontWeight: '700', fontSize: 15 },
  errorBox: {
    backgroundColor: '#fef2f2',
    borderColor: '#fecaca',
    borderWidth: 1,
    borderRadius: 8,
    padding: 14,
    marginBottom: 20,
  },
  errorText: { color: '#b91c1c', fontSize: 13 },
  resultCard: {
    backgroundColor: '#0f172a',
    borderRadius: 12,
    padding: 16,
  },
  resultTitle: { color: '#38bdf8', fontSize: 14, fontWeight: '700', marginBottom: 8 },
  jsonText: { color: '#e2e8f0', fontFamily: 'monospace', fontSize: 11 },
});
