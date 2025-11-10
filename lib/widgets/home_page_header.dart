// lib/widgets/home_page_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../screen/about_page.dart';
import '../screen/config_page.dart';

class HomePageHeader extends StatefulWidget {
  const HomePageHeader({super.key});

  @override
  State<HomePageHeader> createState() => _HomePageHeaderState();
}

class _HomePageHeaderState extends State<HomePageHeader> {
  int _tapCount = 0;
  DateTime? _lastTapTime;
  String _userName = 'Loading...';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final userName = await _storage.read(key: 'user_name');
    if (mounted) {
      setState(() {
        _userName = userName ?? 'User';
      });
    }
  }

  void _handleInfoIconTap() {
    final now = DateTime.now();

    // Reset counter if more than 2 seconds have passed since last tap
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 1)) {
      _tapCount = 0;
    }

    _tapCount++;
    _lastTapTime = now;

    if (_tapCount == 7) {
      // Navigate to Config page after 7 taps
      _tapCount = 0;
      _lastTapTime = null;
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ConfigPage()),
        );
      }
    } else if (_tapCount == 1) {
      // Delay navigation to About page to allow for multiple taps
      Future.delayed(const Duration(seconds: 2), () {
        if (_tapCount == 1 && mounted) {
          // Only navigate if still at 1 tap after delay
          _tapCount = 0;
          _lastTapTime = null;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutPage()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.0,
      color: Colors.teal[400],
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25.0,
            backgroundColor: Colors.purple[700],
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                width: 50.0,
                height: 50.0,
              ),
            ),
          ),
          const SizedBox(width: 15.0),

          const Text(
            'ລະບົບຂາຍປີ້ສວນສະໜຸກ',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const Spacer(),

          Row(
            children: [
              const Icon(Icons.person, color: Colors.white, size: 24.0),
              const SizedBox(width: 8.0),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20.0),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: _handleInfoIconTap,
            tooltip: 'ຂໍ້ມູນ',
          ),
        ],
      ),
    );
  }
}
