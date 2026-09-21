import 'package:flutter/material.dart';
import 'package:sentinel_flutter/sentinel_flutter.dart';
import 'dart:convert';

void main() {
  runApp(const SentinelSampleApp());
}

class SentinelSampleApp extends StatelessWidget {
  const SentinelSampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentinel Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const SentinelHomePage(),
    );
  }
}

class SentinelHomePage extends StatefulWidget {
  const SentinelHomePage({super.key});

  @override
  State<SentinelHomePage> createState() => _SentinelHomePageState();
}

class _SentinelHomePageState extends State<SentinelHomePage> {
  final _nameController = TextEditingController(text: 'João da Silva');
  final _documentController = TextEditingController(text: '123.456.789-09');
  final _emailController = TextEditingController(text: 'joao.silva@example.com');
  final _phoneController = TextEditingController(text: '+5511999998888');

  bool _loading = false;
  SentinelCaptureResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize Sentinel SDK
    SentinelSDK.initialize(
      apiKey: 'test_client_api_key_12345',
      environment: 'production',
    );
  }

  Future<void> _runCapture() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await SentinelSDK.capture(
        userData: SentinelUserDataInput(
          fullName: _nameController.text,
          documentId: _documentController.text,
          email: _emailController.text,
          phoneNumber: _phoneController.text,
        ),
        timeoutMs: 8000,
      );

      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentinel Security SDK'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _documentController,
                      decoration: const InputDecoration(labelText: 'CPF / Document ID'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email Address'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _loading ? null : _runCapture,
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Run Sentinel Capture'),
                    ),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFB91C1C)),
                ),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Risk Level: ${_result!.riskLevel} | Betting Apps: ${_result!.hasBettingApps}',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      const JsonEncoder.withIndent('  ').convert(_result!.toJson()),
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
