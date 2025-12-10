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

  // Voucher
  final TextEditingController voucherController = TextEditingController();
  Map<String, dynamic>? voucherData;
  double diskonVoucher = 0;
  String voucherMessage = '';

  // Pilih tanggal (hanya hari ini)
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

  // Cek voucher
  Future<void> applyVoucher() async {
    final kode = voucherController.text.trim();
    if (kode.isEmpty) {
      setState(() {
        voucherData = null;
        diskonVoucher = 0;
        voucherMessage = '';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token tidak ditemukan. Silakan login ulang.")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("${Config.baseUrl}/api/apply-voucher"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'kode': kode}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          voucherData = data;
          diskonVoucher = 0; // akan dihitung nanti saat total
          if (data['tipe'] == 'persen') {
            voucherMessage = "Potongan ${data['nilai']}%";
          } else {
            voucherMessage = "Potongan Rp${data['nilai']}";
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Voucher berhasil diterapkan: $voucherMessage")),
        );
      } else {
        setState(() {
          voucherData = null;
          diskonVoucher = 0;
          voucherMessage = '';
        });
        final msg = json.decode(response.body)['message'] ?? 'Voucher tidak valid';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
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
          const SnackBar(content: Text("Token tidak ditemukan. Silakan login ulang.")),
        );
        setState(() => loading = false);
        return;
      }

      // Ambil profil user
      final userResponse = await http.get(
        Uri.parse("${Config.baseUrl}/api/user/profile"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (userResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengambil profil: ${userResponse.statusCode}")),
        );
        setState(() => loading = false);
        return;
      }

      final userJson = json.decode(userResponse.body) as Map<String, dynamic>;
      final String namaPelanggan = userJson['username'] ?? widget.username;
      final String? address = (userJson['address'] as String?)?.trim();

      if (address == null || address.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Alamat belum diisi di profil.")),
        );
        setState(() => loading = false);
        return;
      }

      // Hitung total harga default (jumlah = 0, nanti admin update)
      double totalHarga = 0;
      double diskon = 0;
      if (voucherData != null) {
        if (voucherData!['tipe'] == 'persen') {
          diskon = totalHarga * (voucherData!['nilai'] / 100);
        } else {
          diskon = voucherData!['nilai'].toDouble();
        }
        if (diskon > totalHarga) diskon = totalHarga;
      }

      final body = {
  'nama_pelanggan': namaPelanggan,
  'layanan': selectedLayanan!,
  'tanggal': tanggalFormatted,
  'address': address,
  'voucher_id': voucherData != null ? voucherData!['voucher_id'] : null,
  'diskon': diskon,
  'total_akhir': totalHarga - diskon,
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
        title: Text('Buat Pesanan (${widget.username})'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedLayanan,
                hint: const Text('Pilih Jenis Layanan'),
                onChanged: (value) => setState(() => selectedLayanan = value),
                items: const [
                  DropdownMenuItem(value: 'Cuci Kering', child: Text('Cuci Kering')),
                  DropdownMenuItem(value: 'Cuci Setrika', child: Text('Cuci Setrika')),
                  DropdownMenuItem(value: 'Setrika', child: Text('Setrika')),
                ],
                decoration: InputDecoration(
                  labelText: "Layanan",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null ? 'Layanan harus dipilih' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: voucherController,
                decoration: InputDecoration(
                  labelText: "Kode Voucher (opsional)",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: applyVoucher,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (voucherMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text("Voucher: $voucherMessage", style: const TextStyle(color: Colors.green)),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDate == null
                          ? 'Belum pilih tanggal'
                          : 'Tanggal: ${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}',
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => pilihTanggal(context),
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pilih Tanggal'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : buatPesanan,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Buat Pesanan'),
                ),
              ),
              const SizedBox(height: 20),
              if (isConfirming && pesananData != null)
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Pesanan Berhasil", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("Layanan: ${pesananData!['data']['layanan']}"),
                        Text("Tanggal: ${pesananData!['data']['tanggal']}"),
                        Text("Alamat: ${pesananData!['data']['address']}"),
                        if (voucherMessage.isNotEmpty) Text("Voucher: $voucherMessage"),
                        Text("Status: ${pesananData!['data']['status']}"),
                        
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
