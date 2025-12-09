import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:laundry_mobile/config.dart';
import 'package:flutter/scheduler.dart';

class PaymentPage extends StatefulWidget {
  final int pesananId;
  const PaymentPage({super.key, required this.pesananId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool loading = true;
  String status = "Menyiapkan pembayaran...";
  String? payUrl;

  @override
  void initState() {
    super.initState();
    createTransaction();
  }

  Future<void> createTransaction() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    print("=== MIDTRANS DEBUG ===");
    print("URL: ${Config.baseUrl}/api/payment/create-transaction");
    print("Pesanan ID: ${widget.pesananId}");
    print("Token: $token");

    final response = await http.post(
      Uri.parse('${Config.baseUrl}/api/payment/create-transaction'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'pesanan_id': widget.pesananId}),
    );

    print("STATUS CODE: ${response.statusCode}");
    print("RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Backend mengirim: token & redirect_url
      final redirectUrl = data['redirect_url'];

      if (redirectUrl == null) {
        setState(() {
          status = "redirect_url tidak ditemukan.";
          loading = false;
        });
        return;
      }

      // Simpan url final ke payUrl
      payUrl = redirectUrl;

      setState(() {
        status = "Transaksi siap. Tekan Bayar.";
        loading = false;
      });
    } else {
      setState(() {
        status = "Gagal membuat transaksi.";
        loading = false;
      });
    }
  } catch (e) {
    setState(() {
      status = "Error: $e";
      loading = false;
    });
  }
}


  Future<void> openPayment() async {
  if (payUrl == null) return;

  final uri = Uri.parse(payUrl!);

  // Buka browser ke Midtrans
  await launchUrl(uri, mode: LaunchMode.externalApplication);

  // Setelah user balik lagi ke aplikasi → langsung kembali ke daftar pesanan
  SchedulerBinding.instance.addPostFrameCallback((_) {
    Navigator.pop(context, true);
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pembayaran")),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: payUrl == null ? null : openPayment,
                    child: const Text("Bayar Sekarang"),
                  )
                ],
              ),
      ),
    );
  }
}
