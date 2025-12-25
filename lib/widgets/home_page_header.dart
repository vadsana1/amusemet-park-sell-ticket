// lib/widgets/home_page_header.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- Import screens ---
import '../screen/about_page.dart';
import '../screen/config_page.dart';
import '../config/setting_config.dart';
import '../config/sticker_printer_config_page.dart';

// --- Import Service and Model ---
import '../services/profile_api.dart';
import '../services/sticker_printer_service.dart'; // <<< 1. IMPORT NEW SERVICE
import '../services/login_api.dart'; // 🔑 สำหรับเช็ค Admin

class HomePageHeader extends StatefulWidget {
  const HomePageHeader({super.key});

  @override
  State<HomePageHeader> createState() => _HomePageHeaderState();
}

class _HomePageHeaderState extends State<HomePageHeader> {
  // --- Original variables for tap logic ---
  int _tapCount = 0;
  DateTime? _lastTapTime;
  Timer? _tapTimer;

  // --- User and Storage data variables ---
  String _userName = 'Loading...';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // --- Variables for amusement park Profile API ---
  final ProfileApiService _profileService = ProfileApiService();
  String _parkName = 'ລະບົບຂາຍປີ້ສວນສະໜຸກ';
  String? _logoUrl;

  // 2. ✅ [Added] Instance of Service
  final StickerPrinterService _printerService = StickerPrinterService.instance;
  final LoginApi _loginService = LoginApi(); // 🔑 สำหรับเช็ค Admin

  // ❌ [Removed] Printer status variable _isPrinterConnected

  // 🔑 ตัวแปรเช็คว่าเป็น admin หรือไม่
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _debugCheckStorage();
    _loadUserName();
    _fetchProfile();
    _checkAdminStatus(); // 🔑 เช็คว่าเป็น admin หรือไม่
    // ❌ [Removed] _checkPrinterStatus(); (because we listen from Notifier instead)
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    // No need to dispose Notifier because Service is Singleton
    super.dispose();
  }

  // ❌ [Removed] _checkPrinterStatus() function

  // --- Function to fetch amusement park Profile (same as original) ---
  Future<void> _fetchProfile() async {
    final profile = await _profileService.getProfile();
    if (!mounted) return;
    setState(() {
      _parkName = profile.name;
      _logoUrl = profile.picture;
    });
  }

  // --- Function to get User name from Storage (same as original) ---
  Future<void> _loadUserName() async {
    final userName = await _storage.read(key: 'user_name');
    if (mounted) {
      setState(() {
        _userName = userName ?? 'User';
      });
    }
  }

  // 🔑 เช็คว่าผู้ใช้เป็น admin/dev หรือไม่
  Future<void> _checkAdminStatus() async {
    final isAdmin = await _loginService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  Future<void> _debugCheckStorage() async {
    final url = await _storage.read(key: 'base_url');
    if (url == null || url.isEmpty) {
      print('❌ ERROR: base_url ใน storage ว่างเปล่า');
    }
  }

  // --- Logic for Info icon tap (Secret Menu) same as original ---
  void _handleInfoIconTap() {
    final now = DateTime.now();

    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 1)) {
      _tapCount = 0;
    }

    _tapCount++;
    _lastTapTime = now;
    _tapTimer?.cancel();

    if (_tapCount == 7) {
      // Tap 7 times: go to Config page immediately
      _tapCount = 0;
      _lastTapTime = null;
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ConfigPage()),
        );
      }
    } else if (_tapCount == 1) {
      // Tap 1 time: go to About page (wait 2 seconds)
      _tapTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
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
          // --- Logo display section ... (original code) ---
          CircleAvatar(
            radius: 25.0,
            backgroundColor: Colors.purple[700],
            child: ClipOval(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: _logoUrl != null
                    ? Image.network(
                        _logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image_outlined,
                              color: Colors.white, size: 24.0);
                        },
                      )
                    : const Icon(Icons.park, color: Colors.white, size: 30.0),
              ),
            ),
          ),

          const SizedBox(width: 15.0),

          // --- Park name display section ... (original code) ---
          Expanded(
            child: Text(
              _parkName,
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // --- [Important] Printer button with status color (using ValueListenableBuilder) ---
          ValueListenableBuilder<bool>(
            // 3. ✅ [แก้] ฟัง ValueNotifier จาก Service
            valueListenable: _printerService.isConnectedNotifier,
            builder: (context, isConnected, child) {
              final statusColor =
                  isConnected ? Colors.greenAccent : Colors.redAccent;

              return Container(
                margin: const EdgeInsets.only(right: 15.0),
                decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.2), // Transparent button background
                    shape: BoxShape.circle,
                    border: Border.all(
                      // Border color based on status from Service
                      color: statusColor,
                      width: 2.0,
                    )),
                child: IconButton(
                  icon: Icon(
                    Icons.print,
                    // Icon color based on status from Service
                    color: statusColor,
                    size: 26.0,
                  ),
                  tooltip: 'ตັ້ງຄ່າປຣິນເຕີ',
                  onPressed: () {
                    // Pressed then go to Config Printer page immediately
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StickerPrinterConfigPage(),
                      ),
                    );
                    // ❌ No need .then((_) { _checkPrinterStatus(); }) anymore
                    // because ValueListenableBuilder will update automatically
                  },
                ),
              );
            },
          ),
          // --- End ValueListenableBuilder ---

          // --- Settings button (Print Settings) - 🔑 แสดงเฉพาะ Admin เท่านั้น ---
          if (_isAdmin)
            Container(
              margin: const EdgeInsets.only(right: 15.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 26.0,
                ),
                tooltip: 'ການຕັ້ງຄ່າ (Admin only)',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingConfig(),
                    ),
                  );
                },
              ),
            ),

          // --- User name display section (same as original) ---
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

          // --- Info button (Secret Menu) same as original ---
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
