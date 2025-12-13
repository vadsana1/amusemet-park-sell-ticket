import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'user_manual_screen.dart';
import '../services/login_api.dart';
import 'login_page.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LoginApi _loginApi = LoginApi();
  String _userName = 'ກຳລັງໂຫຼດ...'; // Loading...
  String _userId = '';
  String _appVersion = '...'; // App version from pubspec

  // สีหลักของแอป (Teal/Green tone)
  final Color _primaryColor = const Color(0xFF1A9A8B);

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion =
            'Version ${packageInfo.version}+${packageInfo.buildNumber}';
      });
    }
  }

  Future<void> _loadUser() async {
    final name = await _storage.read(key: 'user_name');
    final id = await _storage.read(key: 'user_id');
    if (mounted) {
      setState(() {
        _userName = name ?? 'ຜູ້ໃຊ້'; // User
        _userId = id ?? '-';
      });
    }
  }

  void _navigateToManual() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const UserManualScreen()));
  }

  // --- ฟังก์ชันออกจากระบบ (ภาษาลาว) ---
  Future<void> _logout() async {
    // 1. แสดง Dialog ยืนยัน
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ອອກຈາກລະບົບ'), // Logout title
        content: const Text(
          'ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການອອກຈາກລະບົບ?',
        ), // Are you sure?
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'ຍົກເລີກ',
              style: TextStyle(color: Colors.grey),
            ), // Cancel
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'ຢືນຢັນ',
              style: TextStyle(color: Colors.red),
            ), // Confirm
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 2. เรียก logout API
        await _loginApi.logout();

        if (mounted) {
          // 3. กลับไปหน้า Login
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        // Ignore logout errors and proceed to login page
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'ໂປຣໄຟລ໌', // Profile
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- 1. ส่วนแสดงข้อมูลผู้ใช้ (Profile Card) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: const CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      // child: Text(
                      //   'ID: $_userId',
                      //   style: const TextStyle(
                      //     fontSize: 14,
                      //     color: Colors.white,
                      //     fontWeight: FontWeight.w500,
                      //   ),
                      // ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- 2. ส่วนเมนู (Menu Section) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 10),
                    child: Text(
                      "", // General Menu
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _buildMenuItem(
                      icon: Icons.menu_book_rounded,
                      color: _primaryColor,
                      text: 'ຄູ່ມືການນຳໃຊ້', // User Manual
                      onTap: _navigateToManual,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- ปุ่มออกจากระบบ ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _buildMenuItem(
                      icon: Icons.logout_rounded,
                      color: Colors.redAccent,
                      text: 'ອອກຈາກລະບົບ', // Logout
                      textColor: Colors.redAccent,
                      onTap: _logout,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            Text(
              _appVersion,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color color,
    required String text,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.grey[800],
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.grey,
      ),
    );
  }
}
