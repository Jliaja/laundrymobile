import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:laundry_mobile/config.dart';

class VerifikasiOtpScreen extends StatefulWidget {
  final String email;
  final VoidCallback? onVerified;
  final String purpose;

  const VerifikasiOtpScreen({
    super.key,
    required this.email,
    this.onVerified,
    this.purpose = 'register',
  });

  @override
  State<VerifikasiOtpScreen> createState() => _VerifikasiOtpScreenState();
}

class _VerifikasiOtpScreenState extends State<VerifikasiOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isResending = false;
  bool _canResend = true;
  bool _isLoading = false; // ini ditambah
  String? _errorMessage;

  // -------------------- VERIFIKASI OTP --------------------
  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      setState(() => _errorMessage = 'Kode OTP wajib diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final endpoint = widget.purpose == 'forgot'
    ? '/api/account/verify-otp-forgot'
    : '/api/account/verify-otp';

      final response = await http.post(
        Uri.parse('${Config.baseUrl}$endpoint'),
        headers: {'Accept': 'application/json'},
        body: {'email': widget.email, 'kode': _otpController.text},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'OTP berhasil diverifikasi!'),
              duration: const Duration(seconds: 1),
            ),
          );
        }

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        setState(() {
          _errorMessage =
              data['error'] ?? data['message'] ?? 'OTP salah atau kedaluwarsa';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // -------------------- KIRIM ULANG OTP --------------------
  Future<void> _resendOtp() async {
    if (!_canResend || !mounted) return;

    setState(() {
      _isResending = true;
      _canResend = false;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/account/resend-otp'),
        headers: {'Accept': 'application/json'},
        body: {
          'email': widget.email,
          'type': widget.purpose, // pakai purpose
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'OTP baru berhasil dikirim!'),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        Timer(const Duration(seconds: 30), () {
          if (mounted) setState(() => _canResend = true);
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                data['error'] ?? data['message'] ?? 'Gagal mengirim ulang OTP';
            _canResend = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: $e';
          _canResend = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi OTP'),
        backgroundColor: const Color(0xFF3498db),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Masukkan kode OTP yang dikirim ke ${widget.email}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kode OTP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3498db),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Verifikasi',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
              const SizedBox(height: 10),
              _isResending
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: _canResend ? _resendOtp : null,
                      child: Text(
                        _canResend ? 'Kirim Ulang OTP' : 'Tunggu 30 detik...',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
