import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import './register_page.dart';
import './login_page.dart';
import './home_page.dart';
import '../services/register_api.dart';
import '../services/login_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class InitializationPage extends StatefulWidget {
  const InitializationPage({super.key});

  @override
  State<InitializationPage> createState() => _InitializationPageState();
}

class _InitializationPageState extends State<InitializationPage> {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAppStatus();
  }

  Future<String> _getDeviceId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceId = '';

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      }

      return deviceId;
    } catch (e) {
      return '';
    }
  }

  Future<void> _checkAppStatus() async {
    // Small delay for splash effect
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Check if base URL and token are configured
    final baseUrl = await _storage.read(key: 'base_url');
    final token = await _storage.read(key: 'base_token');

    if (baseUrl == null || baseUrl.isEmpty || token == null || token.isEmpty) {
      // Not configured, stay on register page (config is admin only)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const RegisterPage()),
        );
      }
      return;
    }

    // Get device ID from hardware
    final deviceId = await _getDeviceId();

    if (deviceId.isEmpty) {
      // Can't get device ID, go to register page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const RegisterPage()),
        );
      }
      return;
    }

    // Check if device is registered in backend
    final registerApi = RegisterApi();
    final isRegistered = await registerApi.verifyDevice(deviceId);

    if (!mounted) return;

    if (!isRegistered) {
      // Not registered in backend, go to register page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RegisterPage()),
      );
      return;
    }

    // Device is registered, check if user is logged in
    final loginApi = LoginApi();
    final isLoggedIn = await loginApi.isUserLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // User is logged in, go to main app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // User not logged in, go to login page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15A19A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 150,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_not_supported,
                size: 150,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'ກຳລັງໂຫຼດ...',
              style: GoogleFonts.notoSansLao(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
