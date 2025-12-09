import 'package:flutter/material.dart';
import 'profile.dart';
import 'order.dart';
import 'order_list_page.dart';
import 'login_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:laundry_mobile/config.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ========================= USER DATA =========================
  String username = "";
  String? profileImageUrl;
  bool loadingUser = true;

  // ========================= HARGA DATA =========================
  List<dynamic> _hargaList = [];
  bool _loadingHarga = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
    _fetchHarga();
  }

  // ========================= FETCH USER PROFILE =========================
  Future<void> fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final res = await http.get(
        Uri.parse("${Config.baseUrl}/api/user/profile"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          username = data["username"] ?? "";
          profileImageUrl =
              "${data["profile_picture"]}?v=${DateTime.now().millisecondsSinceEpoch}";
          loadingUser = false;
        });
      } else {
        setState(() => loadingUser = false);
      }
    } catch (e) {
      setState(() => loadingUser = false);
    }
  }

  // ========================= FETCH HARGA =========================
  Future<void> _fetchHarga() async {
  try {
    final prefs = await SharedPreferences.getInstance();
final token = prefs.getString("token");

final response = await http.get(
  Uri.parse('${Config.baseUrl}/api/harga'),
  headers: {
    "Accept": "application/json",
    "Authorization": "Bearer $token",
  },

    );

    if (response.statusCode == 200) {
      setState(() {
        _hargaList = json.decode(response.body);
        _loadingHarga = false;
      });
    } else {
      setState(() => _loadingHarga = false);
    }
  } catch (e) {
    print("ERROR: $e");
    setState(() => _loadingHarga = false);
  }
}


  // ========================= AUTO REFRESH PROFILE =========================
  Future<void> _openProfilePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );

    // 🔥 Jika ProfilePage mengembalikan true, refresh profile
    if (result == true) {
      setState(() {
        loadingUser = true;
      });
      fetchProfile();
    }
  }

  // ========================= MANUAL REFRESH =========================
  Future<void> _refreshAll() async {
    setState(() {
      loadingUser = true;
      _loadingHarga = true;
    });
    await Future.wait([
      fetchProfile(),
      _fetchHarga(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 25),
                _buildMenuRow(context),
                const SizedBox(height: 35),
                const Text(
                  "💰 Daftar Harga Layanan",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _loadingHarga
                    ? const Center(child: CircularProgressIndicator())
                    : _hargaList.isEmpty
                        ? const Text("Belum ada data harga.")
                        : Column(
                            children: _hargaList.map((harga) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.local_laundry_service,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          harga['layanan'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "Rp ${harga['hargaPerKg']}/Kg",
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            key: ValueKey(profileImageUrl),
            backgroundImage: profileImageUrl != null
                ? NetworkImage(profileImageUrl!)
                : const AssetImage("assets/images/profile.jpg") as ImageProvider,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Selamat Datang Di Cemerlang Laundry",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Text(
                //   username.isNotEmpty ? username : "Loading...",
                //   style: const TextStyle(
                //     fontSize: 17,
                //     color: Colors.white,
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _menuItem(
          icon: Icons.shopping_bag,
          label: "Order",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderScreen(username: username),
              ),
            );
          },
        ),
        _menuItem(
          icon: Icons.list,
          label: "Daftar Order",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderListPage()),
            );
          },
        ),
        _menuItem(
          icon: Icons.person,
          label: "Profil",
          onTap: _openProfilePage,
        ),
      ],
    );
  }

  Widget _menuItem(
      {required IconData icon, required String label, required Function onTap}) {
    return InkWell(
      onTap: () => onTap(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 30, color: Colors.blue),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
  return Drawer(
    child: Column(
      children: [
        // BAGIAN PROFILE DI TENGAH
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 50), // spacing atas
              Center(
                child: CircleAvatar(
                  radius: 50,
                  key: ValueKey(profileImageUrl),
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl!)
                      : const AssetImage("assets/images/profile.jpg")
                          as ImageProvider,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  username,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // BAGIAN LOGOUT DI PUNCAK BAWAH
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title:
                  const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove("token");

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 20), // spacing bawah
          ],
        ),
      ],
    ),
  );
}
}
