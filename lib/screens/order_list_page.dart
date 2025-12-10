import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_page.dart';
import 'package:laundry_mobile/config.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> pesananList = [];
  bool isLoading = true;

  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 5, vsync: this);
    fetchPesananUser();
  }

  Future<void> fetchPesananUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/pesanan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          pesananList = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String formatRupiah(dynamic number) {
    if (number == null) return 'Rp 0';
    double? value = double.tryParse(number.toString()) ?? 0.0;
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pesanan Saya"),
        backgroundColor: Colors.blue,
        bottom: TabBar(
          controller: tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Hitung"),
            Tab(text: "Proses"),
            Tab(text: "Selesai"),
            Tab(text: "Cancel"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pesananList.isEmpty
              ? const Center(child: Text("Belum ada pesanan."))
              : TabBarView(
                  controller: tabController,
                  children: [
                    _buildTabList("pending"),
                    _buildTabList("hitung"),
                    _buildTabList("proses"),
                    _buildTabList("selesai"),
                    _buildTabList("cancel"),
                  ],
                ),
    );
  }

  /// ===================== TAB BUILDER =====================
  Widget _buildTabList(String status) {
    final filtered = pesananList.where((p) {
      final s = (p['status'] ?? "").toString().toLowerCase();

      if (s == "pending") return status == "pending";
      if (s == "hitung berat dan harga") return status == "hitung";
      if (s == "proses") return status == "proses";
      if (s == "selesai") return status == "selesai";
      if (s == "dibatalkan") return status == "cancel";

      return false;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text("Tidak ada pesanan"));
    }

    return RefreshIndicator(
      onRefresh: fetchPesananUser,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final p = filtered[index];
          return _buildShopeeCard(p);
        },
      ),
    );
  }

  /// ===================== SHOPEE STYLE CARD =====================
  Widget _buildShopeeCard(dynamic p) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.local_laundry_service,
                    color: Colors.blue, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Pesanan #${p['id']}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _statusBadge(p['status']),
              ],
            ),

            const Divider(height: 22),

            // Detail
            _rowItem("Layanan", p['layanan'] ?? "-"),
            _rowItem("Jumlah", "${p['jumlah'] ?? 0} kg"),
            _rowItem("Harga", formatRupiah(p['total_akhir'])),
            _rowItem(
              "Tanggal",
              (p['tanggal'] != null)
                  ? DateFormat('dd-MM-yyyy')
                      .format(DateTime.parse(p['tanggal']))
                  : "-",
            ),

            const SizedBox(height: 10),

            // Tombol Bayar
            if ((p['status_pembayaran'] ?? "") == "pending")
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PaymentPage(pesananId: p['id']),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Bayar Sekarang"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ===================== ROW ITEM =====================
  Widget _rowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  /// ===================== BADGE STATUS =====================
  Widget _statusBadge(String? status) {
    String s = (status ?? "").toLowerCase();

    Color color = Colors.grey;
    String label = "-";

    if (s == "pending") {
      color = Colors.blue;
      label = "Pending";
    } else if (s == "hitung berat dan harga") {
      color = Colors.blue;
      label = "Hitung";
    } else if (s == "proses") {
      color = Colors.blue;
      label = "proses";
    } else if (s == "selesai") {
      color = Colors.green;
      label = "Selesai";
    } else if (s == 'dibatalkan' || s == 'cancel') {
  color = Colors.red;
  label = "Dibatalkan";

    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
