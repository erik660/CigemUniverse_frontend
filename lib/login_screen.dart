import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'services/history_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordObscured = true;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  // Palet Warna Cigem Creative
  final Color cigemTeal = const Color(0xFF3EB49F);
  final Color bgLight = const Color(0xFFF9FAFB);
  final Color textDark = const Color(0xFF1E1E1E);
  final Color textGrey = const Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(), // Mematikan scroll/bouncing
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Logo Perusahaan (Cigem Creative)
                SizedBox(
                  height: 160, 
                  width: double.infinity,
                  child: Transform.scale(
                    scale: 1.5, // Scale diturunkan ke 1.5 agar tidak kepotong di atas
                    child: Image.asset(
                      'assets/images/logocigem_1_backup.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text('Logo tidak ditemukan'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24), // Jarak ditambahkan agar logo tidak menabrak teks

                // 2. Header Teks
                Text(
                  'CIGEM UNIVERSE',
                  style: GoogleFonts.fredoka(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: cigemTeal,
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Form Container dengan Border
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  padding: const EdgeInsets.all(24), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email Address
                      Text(
                        'Username',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            hintText: 'name@cigem.com',
                            hintStyle: TextStyle(color: textGrey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Password
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _isPasswordObscured,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: TextStyle(color: textGrey, fontSize: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordObscured
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: textGrey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordObscured = !_isPasswordObscured;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            String username = _usernameController.text.trim();
                            String password = _passwordController.text;

                            if (username.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Username dan Password harus diisi!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            final prefs = await SharedPreferences.getInstance();
                            String savedUser = prefs.getString('profile_username') ?? 'erio';
                            String savedPass = prefs.getString('profile_password') ?? 'cigemoke';

                            // Validasi credential
                            bool isValidUser = false;
                            if (username == savedUser && password == savedPass) {
                              isValidUser = true;
                            } else if (username == 'rafa' && password == 'CigemCreativeUniverse2') {
                              isValidUser = true;
                            }

                            if (!isValidUser) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('❌ Username atau Password salah!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }

                            // Login berhasil - save username
                            await HistoryService.saveUsername(username);

                            // Navigate ke Home
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cigemTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 6. Footer Forgot Password & Contact Admin
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Lupa Password? ",
                      style: TextStyle(color: textGrey, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Hubungi Admin',
                          style: TextStyle(
                            color: cigemTeal,
                            fontWeight: FontWeight.bold,
                          ),
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
