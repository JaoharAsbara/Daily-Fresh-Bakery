import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  bool _isLoggedIn = false;
  String _generatedOtp = '';
  String fonnteToken = 'pdqRozGJH8Thrauirume';
  String? _phoneNumber;

  @override
  void initState() {
    super.initState();
    _checkIfUserLoggedIn();
  }

  void _checkIfUserLoggedIn() {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _isLoggedIn = true;
      });
    } else {
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  Future<void> _sendOtp() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan email')),
      );
      return;
    }

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengguna tidak ditemukan')),
        );
        return;
      }

      _phoneNumber = snapshot.docs.first.data()['phone'] ?? '';
      String otp = (100000 +
              (999999 - 100000) *
                  (DateTime.now().millisecondsSinceEpoch % 1000000) /
                  1000000)
          .toInt()
          .toString();
      _generatedOtp = otp;

      final response = await http.post(
        Uri.parse('https://api.fonnte.com/send'),
        headers: {
          'Authorization': fonnteToken,
        },
        body: {
          'target': _phoneNumber,
          'message': 'Kode OTP Anda adalah: $otp',
          'type': 'text',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _isOtpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP telah dikirim ke WhatsApp')),
        );
      } else {
        throw Exception('Gagal mengirim OTP');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim OTP: $e')),
      );
    }
  }

  void _verifyOtp() {
    if (_otpController.text == _generatedOtp) {
      setState(() {
        _isOtpVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP berhasil diverifikasi')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP salah')),
      );
    }
  }

  Future<void> _resetPassword() async {
    String newPassword = _passwordController.text.trim();
    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan kata sandi baru')),
      );
      return;
    }

    try {
      User? user = _auth.currentUser;

      if (user != null) {
        await user.updatePassword(newPassword);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kata sandi berhasil direset')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengguna tidak terautentikasi')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mereset kata sandi: $e')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lupa Password',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Form Kirim Email untuk OTP
                _isLoggedIn
                    ? Card(
                        elevation: 5,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              TextField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.brown,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15.0,
                                    horizontal: 30.0,
                                  ),
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(fontSize: 16),
                                ),
                                child: const Text('Kirim OTP'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: const Text(
                          "Anda harus login untuk mereset kata sandi.",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),

                const SizedBox(height: 20),
                if (_isOtpSent)
                  // Form OTP Verifikasi
                  Card(
                    elevation: 5,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'OTP telah dikirim. Silakan periksa WhatsApp Anda.',
                            style: TextStyle(color: Colors.green),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _otpController,
                            decoration: const InputDecoration(
                              labelText: 'Masukkan OTP',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              padding: const EdgeInsets.symmetric(
                                vertical: 15.0,
                                horizontal: 30.0,
                              ),
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                            child: const Text('Verifikasi OTP'),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
                if (_isOtpVerified)
                  // Form Reset Password
                  Card(
                    elevation: 5,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Kata Sandi Baru',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              padding: const EdgeInsets.symmetric(
                                vertical: 15.0,
                                horizontal: 30.0,
                              ),
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                            child: const Text('Reset Kata Sandi'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
