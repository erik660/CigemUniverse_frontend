import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color cigemGreen = const Color(0xFF3EB49F);
  final Color bgLight = const Color(0xFFF9FAFB);
  final Color textDark = const Color(0xFF1E1E1E);
  final Color textGrey = const Color(0xFF6B7280);

  bool _isPasswordObscured = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _displayName = 'Erio';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('profile_name') ?? 'Erio';
      _usernameController.text = prefs.getString('profile_username') ?? 'erio';
      _passwordController.text = prefs.getString('profile_password') ?? 'cigemoke';
      _displayName = _nameController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context), // Kembali ke Home
        ),
        title: Text(
          'Profil Saya',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // 1. Foto Profil & Nama
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFE5E7EB),
                    child: Icon(Icons.person, color: Colors.grey, size: 60),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _displayName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. Kartu Form Edit Profil
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                // MENGGUNAKAN ATURAN BARU FLUTTER UNTUK TRANSPARANSI (withValues)
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Nama Lengkap'),
                  _buildTextField(controller: _nameController),
                  const SizedBox(height: 16),

                  _buildInputLabel('Username'),
                  _buildTextField(controller: _usernameController),
                  const SizedBox(height: 16),

                  _buildInputLabel('Password Baru'),
                  _buildPasswordField(),
                  const SizedBox(height: 8),

                  Text(
                    'Gunakan minimal 8 karakter dengan angka',
                    style: TextStyle(color: textGrey, fontSize: 12),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('profile_name', _nameController.text);
                        await prefs.setString('profile_username', _usernameController.text);
                        await prefs.setString('profile_password', _passwordController.text);
                        setState(() {
                          _displayName = _nameController.text;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Profil berhasil diperbarui!'),
                              backgroundColor: cigemGreen,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cigemGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Kartu Privasi & Bahasa
            Row(
              children: [
                Expanded(
                  child: _buildSmallCard(
                    icon: Icons.security_outlined,
                    iconBg: cigemGreen.withValues(
                      alpha: 0.1,
                    ), // Aturan baru Flutter
                    iconColor: cigemGreen,
                    title: 'Privasi',
                    subtitle: 'Keamanan',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSmallCard(
                    icon: Icons.translate,
                    iconBg: Colors.orange.withValues(
                      alpha: 0.1,
                    ), // Aturan baru Flutter
                    iconColor: Colors.orange,
                    title: 'Bahasa',
                    subtitle: 'Indonesia',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4. Tombol Keluar Akun
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Menghapus semua halaman sebelumnya dan kembali ke Login
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text(
                  'Keluar Akun',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: Colors.red.withValues(alpha: 0.3),
                  ), // Aturan baru Flutter
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.red.withValues(
                    alpha: 0.02,
                  ), // Aturan baru Flutter
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- Widget Helpers untuk merapikan kode utama ---

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
          color: textDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
          ), // Aturan baru Flutter
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
          ), // Aturan baru Flutter
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _isPasswordObscured,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildSmallCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03), // Aturan baru Flutter
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: textGrey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
