// lib/widgets/home_page_header.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- Import หน้าจอต่างๆ ---
import '../screen/about_page.dart';
import '../screen/config_page.dart';
import '../config/sticker_printer_config_page.dart';

// --- Import Service และ Model ---
import '../services/profile_api.dart';
import '../services/sticker_printer_service.dart'; // <<< 1. IMPORT SERVICE ใหม่

class HomePageHeader extends StatefulWidget {
  const HomePageHeader({super.key});

  @override
  State<HomePageHeader> createState() => _HomePageHeaderState();
}

class _HomePageHeaderState extends State<HomePageHeader> {
  // --- ตัวแปรเดิมสำหรับ Logic การกด ---
  int _tapCount = 0;
  DateTime? _lastTapTime;
  Timer? _tapTimer;

  // --- ตัวแปรข้อมูล User และ Storage ---
  String _userName = 'Loading...';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // --- ตัวแปรสำหรับ API Profile สวนสนุก ---
  final ProfileApiService _profileService = ProfileApiService();
  String _parkName = 'ລະບົບຂາຍປີ້ສວນສະໜຸກ';
  String? _logoUrl;

  // 2. ✅ [เพิ่ม] Instance ของ Service
  final StickerPrinterService _printerService = StickerPrinterService.instance;

  // ❌ [ลบ] ตัวแปรสถานะปริ้นเตอร์ _isPrinterConnected ออกไป

  @override
  void initState() {
    super.initState();
    _debugCheckStorage();
    _loadUserName();
    _fetchProfile();
    // ❌ [ลบ] _checkPrinterStatus(); ออกไป (เพราะเราจะฟังจาก Notifier แทน)
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    // ไม่ต้อง dispose Notifier เพราะ Service เป็น Singleton
    super.dispose();
  }

  // ❌ [ลบ] ฟังก์ชัน _checkPrinterStatus() ออกไป

  // --- ฟังก์ชันดึงข้อมูล Profile สวนสนุก (เหมือนเดิม) ---
  Future<void> _fetchProfile() async {
    final profile = await _profileService.getProfile();
    if (!mounted) return;
    setState(() {
      _parkName = profile.name;
      _logoUrl = profile.picture;
    });
  }

  // --- ฟังก์ชันดึงชื่อ User จาก Storage (เหมือนเดิม) ---
  Future<void> _loadUserName() async {
    final userName = await _storage.read(key: 'user_name');
    if (mounted) {
      setState(() {
        _userName = userName ?? 'User';
      });
    }
  }

  Future<void> _debugCheckStorage() async {
    final url = await _storage.read(key: 'base_url');
    if (url == null || url.isEmpty) {
      print('❌ ERROR: base_url ใน storage ว่างเปล่า');
    }
  }

  // --- Logic การกดไอคอน Info (Secret Menu) เหมือนเดิม ---
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
      // กด 7 ครั้ง: เข้าหน้า Config ทันที
      _tapCount = 0;
      _lastTapTime = null;
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ConfigPage()),
        );
      }
    } else if (_tapCount == 1) {
      // กด 1 ครั้ง: เข้าหน้า About (รอ 2 วิ)
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
          // --- ส่วนแสดง Logo ... (โค้ดเดิม) ---
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

          // --- ส่วนแสดงชื่อสวนสนุก ... (โค้ดเดิม) ---
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

          // --- [สำคัญ] ปุ่ม Printer พร้อมสถานะสี (ใช้ ValueListenableBuilder) ---
          ValueListenableBuilder<bool>(
            // 3. ✅ [แก้] ฟัง ValueNotifier จาก Service
            valueListenable: _printerService.isConnectedNotifier,
            builder: (context, isConnected, child) {
              final statusColor =
                  isConnected ? Colors.greenAccent : Colors.redAccent;

              return Container(
                margin: const EdgeInsets.only(right: 15.0),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), // พื้นหลังปุ่มจางๆ
                    shape: BoxShape.circle,
                    border: Border.all(
                      // ขอบสีตามสถานะที่ได้รับจาก Service
                      color: statusColor,
                      width: 2.0,
                    )),
                child: IconButton(
                  icon: Icon(
                    Icons.print,
                    // ไอคอนสีตามสถานะที่ได้รับจาก Service
                    color: statusColor,
                    size: 26.0,
                  ),
                  tooltip: 'ຕັ້ງຄ່າປຣິນເຕີ',
                  onPressed: () {
                    // กดแล้วไปหน้า Config Printer ทันที
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StickerPrinterConfigPage(),
                      ),
                    );
                    // ❌ ไม่ต้อง .then((_) { _checkPrinterStatus(); }) แล้ว
                    // เพราะ ValueListenableBuilder จะอัปเดตเองอัตโนมัติ
                  },
                ),
              );
            },
          ),
          // --- จบ ValueListenableBuilder ---

          // --- ส่วนแสดงชื่อ User (เหมือนเดิม) ---
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

          // --- ปุ่ม Info (Secret Menu) เหมือนเดิม ---
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
