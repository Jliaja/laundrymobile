import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:laundry_mobile/config.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String step = 'email'; // email -> otp -> reset
  String? errorMessage;
  String? successMessage;
  bool _isLoading = false;

  final String baseUrl = '${Config.baseUrl}/api';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ------------------ STEP 1: KIRIM OTP ------------------
  Future<void> sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => errorMessage = 'Email wajib diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/account/send-otp-forgot'),
        headers: {'Accept': 'application/json'},
        body: {'email': email},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          successMessage = data['message'] ?? 'Kode OTP telah dikirim ke email';
          step = 'otp';
        });
        _animController.forward(from: 0);
      } else {
        setState(() => errorMessage = data['error'] ?? data['message'] ?? 'Gagal mengirim OTP');
      }
    } catch (e) {
      setState(() => errorMessage = 'Gagal terhubung ke server');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ------------------ STEP 2: VERIFIKASI OTP ------------------
  Future<void> verifyOtpForgot() async {
    final kode = _otpController.text.trim();
    if (kode.isEmpty) {
      setState(() => errorMessage = 'Kode OTP wajib diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/account/verify-otp-forgot'),
        headers: {'Accept': 'application/json'},
        body: {
          'email': _emailController.text.trim(),
          'kode': kode,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          step = 'reset';
          successMessage = 'OTP benar, silakan buat password baru';
        });
        _animController.forward(from: 0);
      } else {
        setState(() => errorMessage = data['error'] ?? data['message'] ?? 'Kode OTP salah');
      }
    } catch (e) {
      setState(() => errorMessage = 'Gagal terhubung ke server');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ------------------ STEP 3: RESET PASSWORD ------------------
  Future<void> resetPassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      setState(() => errorMessage = 'Password dan konfirmasi wajib diisi');
      return;
    }

    if (password != confirm) {
      setState(() => errorMessage = 'Password dan konfirmasi tidak cocok');
      return;
    }

    setState(() {
      _isLoading = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/account/reset-password'),
        headers: {'Accept': 'application/json'},
        body: {
          'email': _emailController.text.trim(),
          'kode': _otpController.text.trim(),
          'password': password,
          'password_confirmation': confirm,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
  setState(() {
    successMessage = data['message'] ?? 'Password berhasil diubah!';
  });

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage!)),
          );
          Navigator.pop(context);
        }
      } else {
  setState(() {
    errorMessage = data['error'] ?? data['message'] ?? 'Gagal reset password';
  });
}
    } catch (e) {
      setState(() => errorMessage = 'Gagal terhubung ke server');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ------------------ RESEND OTP ------------------
  Future<void> resendOtp() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Masukkan email dulu untuk resend');
      return;
    }
    await sendOtp();
  }

  // ------------------ UI STEP ------------------
  Widget _buildStepForm() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(step),
        children: [
          _buildStepHeader(),
          const SizedBox(height: 12),
          if (step == 'email') _stepEmail(),
          if (step == 'otp') _stepOtp(),
          if (step == 'reset') _stepReset(),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    int current = step == 'email' ? 1 : step == 'otp' ? 2 : 3;
    return Column(
      children: [
        Text('Step $current dari 3', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            bool active = (i + 1) <= current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: active ? 28 : 10,
              height: 8,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1976D2) : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _stepEmail() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1976D2)),
            labelText: 'Email',
            hintText: 'contoh@domain.com',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : sendOtp,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF1976D2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Kirim OTP', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _stepOtp() {
    return Column(
      children: [
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_clock, color: Color(0xFF1976D2)),
            labelText: 'Kode OTP',
            hintText: 'Masukkan kode OTP',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : verifyOtpForgot,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF1976D2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: _isLoading ? null : resendOtp,
              child: const Text('Kirim ulang', style: TextStyle(color: Color(0xFF1976D2))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepReset() {
    return Column(
      children: [
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.key, color: Color(0xFF1976D2)),
            labelText: 'Password Baru',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmController,
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.check, color: Color(0xFF1976D2)),
            labelText: 'Konfirmasi Password',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : resetPassword,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF1976D2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Simpan Password', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _alertBox(String msg, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(.95),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(color == Colors.red ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
          IconButton(
            onPressed: () {
              setState(() {
                errorMessage = null;
                successMessage = null;
              });
            },
            icon: const Icon(Icons.close, color: Colors.white),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3498db),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.local_laundry_service, size: 72, color: Colors.white),
            const SizedBox(height: 12),
            const Text('Lupa Password', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'Masukkan email kamu, kami akan mengirim kode OTP untuk mereset password.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(.9)),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 14, offset: const Offset(0,6))],
              ),
              child: Column(
                children: [
                  if (errorMessage != null) _alertBox(errorMessage!, Colors.red),
                  if (successMessage != null) _alertBox(successMessage!, Colors.green),
                  FadeTransition(opacity: _fadeAnim, child: _buildStepForm()),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () {
                      if (step == 'email') Navigator.pop(context);
                      else setState(() {
                        if (step == 'reset') step = 'otp';
                        else if (step == 'otp') step = 'email';
                        errorMessage = null;
                        successMessage = null;
                      });
                    },
                    child: Text(step == 'email' ? 'Kembali ke Login' : 'Kembali',
                        style: const TextStyle(color: Color(0xFF1976D2))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
