import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final String username;

  const ProfilePage({super.key, required this.username});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _birthDateController;
  late TextEditingController _bioController;
  final _auth = FirebaseAuth.instance;
  late String userId;

  @override
  void initState() {
    super.initState();
    _birthDateController = TextEditingController();
    _bioController = TextEditingController();
    _getUserIdAndLoadData();
  }

  Future<void> _getUserIdAndLoadData() async {
    final user = _auth.currentUser;
    if (user != null) {
      userId = user.uid;
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data();
      setState(() {
        _birthDateController.text = data?['birthDate'] ?? '';
        _bioController.text = data?['bio'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _birthDateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _saveUserData() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'birthDate': _birthDateController.text,
        'bio': _bioController.text,
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil diperbarui'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan data: $e'),
        ),
      );
    }
  }

  Future<void> _deleteUserAccount() async {
    try {
      // Hapus akun pengguna dari Firebase Authentication
      User? user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus akun autentikasi: $e'),
        ),
      );
    }
  }

  Future<void> _deleteUserData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yakin Mau Pamit Nih?'),
        content: const Text('Hapus akun ini? Pasti keputusan terakhir nih?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Hapus data pengguna dari Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .delete();

                // Hapus akun pengguna dari Firebase Authentication
                await _deleteUserAccount();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Akun berhasil dihapus'),
                  ),
                );

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus akun: $e'),
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown[800],
        iconTheme:
            const IconThemeData(color: Colors.white), // Mengubah warna ikon
      ),
      body: Container(
        color: Colors.white, // Mengubah background menjadi putih
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.brown,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.username,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          color:
                              Colors.white, // Mengubah warna card menjadi putih
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _birthDateController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: "Tanggal Lahir",
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: () => _selectDate(context),
                                    ),
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _bioController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: "Bio",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _saveUserData,
                          child: const Text('Simpan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15.0,
                              horizontal: 30.0,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _deleteUserData,
                          child: const Text('Hapus Akun?'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15.0,
                              horizontal: 30.0,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
