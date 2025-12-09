import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laundry_mobile/config.dart';

/* ============================================================
   PROFILE PAGE
   ============================================================ */
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = "";
  String email = "";
  String address = "";
  String? profileImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

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
        email = data["email"] ?? "";
        address = data["address"] ?? "";
        profileImageUrl = data["profile_picture"];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  } catch (_) {
    setState(() => isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Profil"),
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ================= PROFILE HEADER =====================
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.blueAccent],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 55,
                            backgroundImage: profileImageUrl != null
                                ? NetworkImage(profileImageUrl!)
                                : const AssetImage(
                                        "assets/images/profile.jpg")
                                    as ImageProvider,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ================= INFO CARD =====================
                  profileItem(Icons.person, "Username", username),
                  profileItem(Icons.email, "Email", email),
                  profileItem(Icons.home, "Alamat", address),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                            profileData: {
                              "username": username,
                              "email": email,
                              "address": address,
                              "profile_picture": profileImageUrl,
                            },
                          ),
                        ),
                      );

                      if (result == true) {
                        fetchProfile();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Profil berhasil diperbarui!"),
                            
                          ),
                        );
                      }
                    },
                    child: Text(
                          "Edit Profile",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget profileItem(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }
}


/* ============================================================
   EDIT PROFILE PAGE
   ============================================================ */
class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profileData;
  const EditProfilePage({super.key, required this.profileData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController addressController;

  File? selectedImage;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    usernameController =
        TextEditingController(text: widget.profileData['username']);
    emailController =
        TextEditingController(text: widget.profileData['email']);
    addressController =
        TextEditingController(text: widget.profileData['address']);
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<void> updateProfile() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    var url = Uri.parse("${Config.baseUrl}/api/user/profile");

    var request = http.MultipartRequest("POST", url);
    request.headers.addAll({
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    });

    request.fields['username'] = usernameController.text;
    request.fields['email'] = emailController.text;
    request.fields['address'] = addressController.text;

    if (selectedImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
          "profile_picture", selectedImage!.path));
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    setState(() => loading = false);

    if (response.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      debugPrint("UPDATE ERROR: $body");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profil"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ================= AVATAR WITH EDIT BUTTON =====================
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 65,
                  backgroundColor: Colors.blueAccent,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: selectedImage != null
                        ? FileImage(selectedImage!)
                        : (widget.profileData['profile_picture'] != null
                            ? NetworkImage(
                                widget.profileData['profile_picture'])
                            : const AssetImage("assets/images/profile.jpg"))
                            as ImageProvider,
                  ),
                ),
                InkWell(
                  onTap: pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                )
              ],
            ),

            const SizedBox(height: 30),

            textField(Icons.person, "Username", usernameController),
            const SizedBox(height: 15),

            textField(Icons.email, "Email", emailController),
            const SizedBox(height: 15),

            textField(Icons.home, "Alamat", addressController),
            const SizedBox(height: 20),

            // ================= SAVE BUTTON =====================
            ElevatedButton(
              onPressed: loading ? null : updateProfile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                          "Simpan Perubahan",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget textField(IconData icon, String label, TextEditingController c) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
