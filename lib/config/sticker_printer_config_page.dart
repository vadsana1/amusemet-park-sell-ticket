import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ⚠️ ตรวจสอบ Path นี้ให้ตรงกับตำแหน่งไฟล์ Service ของคุณ
import '../services/sticker_printer_service.dart';

// --- Theme Colors ---
class AppTheme {
  static const Color primaryTeal = Color(0xFF009688);
  static const Color accentCream = Color(0xFFF0E6BC);
  static const Color textDark = Color(0xFF2D3436);
  static const Color successGreen = Color(0xFF27AE60);
  static const Color errorRed = Color(0xFFC0392B);
  static const Color warningOrange = Color(0xFFFF9800);
}

// Model ขนาดกระดาษ
class LabelSize {
  final String id;
  final String name;
  final double widthMm;
  final double heightMm;
  const LabelSize(this.id, this.name, this.widthMm, this.heightMm);
}

class StickerPrinterConfigPage extends StatefulWidget {
  const StickerPrinterConfigPage({super.key});

  @override
  State<StickerPrinterConfigPage> createState() =>
      _StickerPrinterConfigPageState();
}

class _StickerPrinterConfigPageState extends State<StickerPrinterConfigPage> {
  // เรียกใช้ Service ตัวเดียวกับทั้งแอป
  // 💡 สมมติว่า Service มี isConnectedNotifier และ setConnectionStatus
  final StickerPrinterService _printerService = StickerPrinterService.instance;

  // ❌ [ลบ] bool _isConnected ออกไป (ใช้ Notifier จาก Service แทน)
  // ❌ [ลบ] void _checkConnectionStatus() ออกไป

  // Settings
  double _darknessLevel = 8.0;

  // รายการขนาดกระดาษ (เหลือแค่ 6x4cm)
  final List<LabelSize> _paperSizes = [
    const LabelSize('60x40', '60 x 40 mm (6 x 4 cm)', 60, 40),
  ];
  late LabelSize _selectedSize;

  @override
  void initState() {
    super.initState();
    _selectedSize = _paperSizes[0];
    _loadSettings();
    // Auto-connect already happens in HomePage, no need to call again here
    // แต่ตรวจสอบสถานะปัจจุบันว่ายังเชื่อมต่ออยู่หรือไม่
    _checkCurrentConnection();
  }

  // ตรวจสอบสถานะการเชื่อมต่อเมื่อเข้าหน้า Config
  Future<void> _checkCurrentConnection() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await _printerService.checkConnection();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darknessLevel = prefs.getDouble('printer_darkness') ?? 8.0;

      // โหลดขนาดกระดาษที่เคยเซฟ
      double w = prefs.getDouble('printer_width') ?? 60.0;
      double h = prefs.getDouble('printer_height') ?? 40.0;

      // หา object ที่ตรงกับขนาดที่โหลดมา
      try {
        _selectedSize = _paperSizes.firstWhere(
          (s) => s.widthMm == w && s.heightMm == h,
          orElse: () => _paperSizes[0],
        );
      } catch (_) {
        _selectedSize = _paperSizes[0];
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('printer_darkness', _darknessLevel);
    await prefs.setDouble('printer_width', _selectedSize.widthMm);
    await prefs.setDouble('printer_height', _selectedSize.heightMm);

    // print(
    //     '✅ Saved: Darkness=$_darknessLevel, Size=${_selectedSize.widthMm}x${_selectedSize.heightMm}');
    // _showSnack("ບັນທຶກສຳເລັດ: ຄວາມເຂັ້ມ ${_darknessLevel.toInt()}",
    // AppTheme.successGreen);
  }

  // --- Actions ---

  Future<void> _handleConnect() async {
    _debugUsbCheck();
  }

  void _handleTestPrint() async {
    // 💡 [แก้] เช็คสถานะจาก ValueNotifier ของ Service
    if (!_printerService.isConnectedNotifier.value) {
      _showSnack("Please connect printer first", AppTheme.errorRed);
      return;
    }

    try {
      // เรียก Test Print ผ่าน Service
      await _printerService.printTicket(
        ticketId: "TEST-001",
        shopName: "TEST PRINT",
        date: "01/01/2025",
        time: "12:00",
        ticketType: "TEST MODE",
        rideList: ["Test Item 1", "Test Item 2"],
        qrData: "123456",
      );

      _showSnack("✅ Sent Test Print command", AppTheme.successGreen);
    } catch (e) {
      _showSnack("❌ Print failed: Connection lost. Please reconnect.",
          AppTheme.errorRed);
    }
  }

  // --- 🛠️ Debug Section (Updated for flutter_usb_printer) ---

  Future<void> _debugUsbCheck() async {
    // 💡 [แก้] ใช้ check mounted ก่อน showDialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // ✅ แก้ไข: ไม่ใช้ Stream/listen แล้ว เพราะ flutter_usb_printer ส่งค่ามาเลย
      List<Map<String, dynamic>> devices = await _printerService.scanDevices();

      if (mounted) Navigator.pop(context); // ปิด Loading

      if (devices.isEmpty) {
        // 💡 [แก้] ใช้ check mounted
        if (mounted) {
          _showSnack("❌ ບໍ່ພົບPrinter USB (ລອງຸອດສຽບໃຫມ่່)", AppTheme.errorRed);
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("ເລືອກ Printer"),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  var d = devices[index];
                  // ✅ แก้ไข: ดึงค่าจาก Map แทน Object
                  String name = d['productName'] ?? "Unknown";
                  String vid = d['vendorId'].toString();
                  String pid = d['productId'].toString();

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading:
                          const Icon(Icons.print, color: AppTheme.primaryTeal),
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("VID: $vid | PID: $pid"),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.warningOrange,
                            foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                          _connectToDevice(d); // ฟังก์ชันเชื่อมต่อ
                        },
                        child: const Text("Connect"),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ປິດ"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      _showSnack("Error: $e", AppTheme.errorRed);
    }
  }

  // ฟังก์ชันเชื่อมต่อ
  // ✅ แก้ไข: รับค่าเป็น Map<String, dynamic>
  Future<void> _connectToDevice(Map<String, dynamic> device) async {
    try {
      // 💡 สมมติว่า _printerService.connect() ถูกปรับให้ return bool
      final success = await _printerService.connect(device);

      // ✅ [สำคัญ] อัปเดตสถานะใน Service
      // บรรทัดนี้คือสิ่งที่ทำให้ Header เปลี่ยนสี
      _printerService.setConnectionStatus(success, device);

      if (success) {
        _showSnack("✅ ເຊື່ອມຕໍ່ສຳເລັດ: ${device['productName']}",
            AppTheme.successGreen);
      } else {
        _showSnack("❌ ເຊື່ອມຕໍ່ບໍ່ສຳເລັດheck logs", AppTheme.errorRed);
      }
    } catch (e) {
      // ✅ [สำคัญ] อัปเดตสถานะใน Service เมื่อมี Exception
      _printerService.setConnectionStatus(false);
      _showSnack("❌ ເຊື່ອມຕໍ່ບໍ່ໄດ້: $e", AppTheme.errorRed);
    }
  }

  void _showSnack(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Printer Setup"),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Status Card
            // ✅ [แก้] ใช้ ValueListenableBuilder เพื่อฟังสถานะจาก Service
            ValueListenableBuilder<bool>(
              valueListenable: _printerService.isConnectedNotifier,
              builder: (context, isConnected, child) {
                // isConnected คือสถานะที่ส่งมาจาก Service
                final statusColor =
                    isConnected ? AppTheme.successGreen : AppTheme.errorRed;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: statusColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                          // 💡 แก้ไข: ใช้ withOpacity(0.05) เพื่อป้องกัน Warning/Error ที่เกี่ยวข้องกับ withValues
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10)
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isConnected ? Icons.check_circle : Icons.error,
                        color: statusColor,
                        size: 40,
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected ? "Connected" : "Disconnected",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          Text(isConnected
                              ? "Ready to Print"
                              : "Please connect printer"),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 2. Main Action Buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _handleConnect,
                icon: const Icon(Icons.usb),
                label: const Text("Scan & Connect Printer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 2.5 Reconnect Button (สำหรับหลังเปลี่ยนกระดาษ)
            ValueListenableBuilder<bool>(
              valueListenable: _printerService.isConnectedNotifier,
              builder: (context, isConnected, child) {
                // แสดงปุ่มเฉพาะเมื่อเชื่อมต่ออยู่
                if (!isConnected) return const SizedBox.shrink();

                return Column(
                  children: [
                    // ปุ่ม Check Status
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final stillConnected =
                              await _printerService.checkConnection();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(stillConnected
                                    ? 'ເຊື່ອມຕໍ່ປົກກະຕິ (Still Connected)'
                                    : 'ຕັດການເຊື່ອມຕໍ່ແລ້ວ (Disconnected)'),
                                backgroundColor:
                                    stillConnected ? Colors.green : Colors.red,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.wifi_find),
                        label: const Text("Check Status"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueGrey,
                          side: const BorderSide(
                              color: Colors.blueGrey, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // ปุ่ม Reconnect
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // เชื่อมต่อใหม่กับเครื่องพิมพ์ที่บันทึกไว้
                          await _printerService.autoConnectOnStartup();

                          if (!mounted) return;

                          // เช็คสถานะการเชื่อมต่อหลังจากพยายาม reconnect
                          final bool isConnected =
                              _printerService.isConnectedNotifier.value;

                          if (!mounted) return;

                          if (isConnected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'ເຊື່ອມຕໍ່ໃໝ່ສຳເລັດ (Reconnected successfully)'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('ເຊື່ອມຕໍ່ໃໝ່ບໍ່ສຳເລັດ ກະລຸນາລອງໃໝ່'),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text("Reconnect (ຫຼັງປ່ຽນກະເຈ້ຍ)"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryTeal,
                          side:
                              BorderSide(color: AppTheme.primaryTeal, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            // 3. Configuration Form
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Configuration",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),

            // Paper Size Display (แสดงเฉพาะ 6x4cm)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Paper Size:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _selectedSize.name,
                    style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 4. Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text("ບັນທຶກ"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 5. Test Print Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _handleTestPrint,
                icon: const Icon(Icons.print),
                label: const Text("Test Print Sample"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
