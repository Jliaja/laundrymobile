import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laundry_mobile/config.dart';

class OrderScreen extends StatefulWidget {
  final String username;
  const OrderScreen({super.key, required this.username});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  String? selectedLayanan;
  Map<String, dynamic>? pesananData;
  bool isConfirming = false;
  bool loading = false;

  // Pilih tanggal, hanya hari ini
  Future<void> pilihTanggal(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final today = DateTime.now();
      if (pickedDate.year == today.year &&
          pickedDate.month == today.month &&
          pickedDate.day == today.day) {
        setState(() {
          selectedDate = pickedDate;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tanggal harus hari ini.")),
        );
      }
    }
  }

  // Buat pesanan
  Future<void> buatPesanan() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih tanggal terlebih dahulu")),
      );
      return;
    }

    setState(() => loading = true);

    final tanggalFormatted =
        "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token tidak ditemukan. Silakan login ulang."),
          ),
        );
        setState(() => loading = false);
        return;
      }

      // Ambil profil user untuk nama & alamat
      final userResponse = await http.get(
        Uri.parse("${Config.baseUrl}/api/user/profile"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (userResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Gagal mengambil profil: ${userResponse.statusCode}"),
          ),
        );
        setState(() => loading = false);
        return;
      }

      final userJson = json.decode(userResponse.body) as Map<String, dynamic>;
      final String namaPelanggan = userJson['username'] ?? widget.username;
      final String? address = (userJson['address'] as String?)?.trim();

      if (address == null || address.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Alamat belum diisi di profil. Silakan isi alamat sebelum membuat pesanan.")),
        );
        setState(() => loading = false);
        return;
      }

      // Body pesanan, tanpa user_id
      final body = {
        'nama_pelanggan': namaPelanggan,
        'layanan': selectedLayanan!,
        'tanggal': tanggalFormatted,
        'address': address, // wajib 'address' sesuai API
      };

      final response = await http.post(
        Uri.parse("${Config.baseUrl}/api/pesanan"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          pesananData = data;
          isConfirming = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pesanan berhasil dikirim!")),
        );
      } else {
        final msg = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Status ${response.statusCode}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal kirim pesanan: $msg")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Buat Pesanan (${widget.username})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      "Form Pemesanan Laundry",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedLayanan,
                      hint: const Text('Pilih Jenis Layanan'),
                      onChanged: (value) =>
                          setState(() => selectedLayanan = value),
                      items: const [
                        DropdownMenuItem(
                            value: 'Cuci Kering', child: Text('Cuci Kering')),
                        DropdownMenuItem(
                            value: 'Cuci Setrika',
                            child: Text('Cuci Setrika')),
                        DropdownMenuItem(value: 'Setrika', child: Text('Setrika')),
                      ],
                      decoration: InputDecoration(
                        labelText: "Layanan",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) =>
                          value == null ? 'Layanan harus dipilih' : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDate == null
                                ? 'Belum pilih tanggal'
                                : 'Tanggal: ${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => pilihTanggal(context),
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Pilih Tanggal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : buatPesanan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Buat Pesanan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isConfirming && pesananData != null)
                      Card(
                        color: Colors.blue[50],
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.receipt_long,
                                      color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    "Pesanan Berhasil",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                  "Layanan: ${pesananData!['layanan'] ?? selectedLayanan}"),
                              Text(
                                  "Status: ${pesananData!['status'] ?? 'pending'}"),
                              Text(
                                  "Tanggal: ${pesananData!['tanggal'] ?? selectedDate}"),
                              if (pesananData!['total_harga'] != null)
                                Text(
                                    "Total Harga: Rp ${pesananData!['total_harga']}"),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
