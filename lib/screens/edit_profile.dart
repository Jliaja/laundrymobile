// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:laundry_mobile/config.dart';

// class EditProfilePage extends StatefulWidget {
//   final Map<String, dynamic> profileData;
//   const EditProfilePage({super.key, required this.profileData});

//   @override
//   State<EditProfilePage> createState() => _EditProfilePageState();
// }

// class _EditProfilePageState extends State<EditProfilePage> {
//   late TextEditingController usernameController;
//   late TextEditingController emailController;
//   late TextEditingController addressController;
//   bool loading = false;

//   @override
//   void initState() {
//     super.initState();
//     usernameController = TextEditingController(
//       text: widget.profileData['username'],
//     );
//     emailController = TextEditingController(text: widget.profileData['email']);
//     addressController = TextEditingController(
//       text: widget.profileData['address'] ?? '',
//     );
//   }

//   Future<void> updateProfile() async {
//     setState(() => loading = true);

//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');

//     if (token == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Token tidak ditemukan, silakan login ulang."),
//         ),
//       );
//       setState(() => loading = false);
//       return;
//     }

//     final url = Uri.parse("${Config.baseUrl}/api/user/profile");

//     try {
//       final response = await http.put(
//         url,
//         headers: {
//           'Accept': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: {
//           'username': usernameController.text,
//           'email': emailController.text,
//           'address': addressController.text,
//         },
//       );

//       final data = json.decode(response.body);
//       debugPrint('Response update: ${response.body}');

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Profil berhasil diperbarui!")),
//         );
//         Navigator.pop(context, true); // balik ke halaman sebelumnya
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Gagal update: ${data['message'] ?? 'Error'}"),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
//     } finally {
//       setState(() => loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Edit Profil")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: usernameController,
//               decoration: const InputDecoration(labelText: 'Username'),
//             ),
//             TextField(
//               controller: emailController,
//               decoration: const InputDecoration(labelText: 'Email'),
//             ),
//             TextField(
//               controller: addressController,
//               decoration: const InputDecoration(labelText: 'Alamat'),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: loading ? null : updateProfile,
//               child: loading
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text("Simpan"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
