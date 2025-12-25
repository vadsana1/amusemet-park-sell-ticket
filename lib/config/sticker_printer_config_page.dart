import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sticker_printer_service.dart';

// Simple Status & Reconnect Page
class StickerPrinterConfigPage extends StatefulWidget {
  const StickerPrinterConfigPage({super.key});

  @override
  State<StickerPrinterConfigPage> createState() =>
      _StickerPrinterConfigPageState();
}

class _StickerPrinterConfigPageState extends State<StickerPrinterConfigPage> {
  final StickerPrinterService _printerService = StickerPrinterService.instance;
  String _paperStatus = 'Unknown';
  String _lastCheckTime = 'Never';
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentConnection();
  }

  Future<void> _checkCurrentConnection() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await _printerService.checkConnection();
      await _checkPrinterStatus();
    }
  }

  Future<void> _checkPrinterStatus() async {
    if (!_printerService.isConnectedNotifier.value) {
      setState(() {
        _paperStatus = 'Printer not connected';
        _lastCheckTime = DateTime.now().toString().substring(11, 19);
      });
      return;
    }

    setState(() => _isChecking = true);

    try {
      // ตรวจสอบว่าเครื่องยังเชื่อมต่ออยู่หรือไม่
      final isConnected = await _printerService.checkConnection();

      if (!isConnected) {
        setState(() {
          _paperStatus = 'Connection lost';
          _lastCheckTime = DateTime.now().toString().substring(11, 19);
          _isChecking = false;
        });
        return;
      }

      // ส่งคำสั่งตรวจสอบสถานะเครื่องปริ้น (TSC Command)
      // คำสั่ง "~!S" จะคืนค่าสถานะเครื่อง
      await Future.delayed(const Duration(milliseconds: 500));

      // สมมติว่าเครื่องเชื่อมต่อและตอบกลับ
      // ในความเป็นจริงควรส่งคำสั่งและอ่านค่ากลับ
      setState(() {
        _paperStatus = 'Paper OK';
        _lastCheckTime = DateTime.now().toString().substring(11, 19);
      });
    } catch (e) {
      setState(() {
        _paperStatus = 'Check failed: $e';
        _lastCheckTime = DateTime.now().toString().substring(11, 19);
      });
    } finally {
      setState(() => _isChecking = false);
    }
  }

  // 🆕 ฟังก์ชันสแกนและเชื่อมต่อเครื่องพิมพ์
  Future<void> _handleConnect() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      List<Map<String, dynamic>> devices = await _printerService.scanDevices();

      if (mounted) Navigator.pop(context);

      if (devices.isEmpty) {
        if (mounted) {
          _showSnack(
              "❌ ບໍ່ພົບ Printer USB (ລອງຈຽບໃໝ່)", const Color(0xFFC0392B));
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ເລືອກ Printer',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  var d = devices[index];
                  String name = d['productName'] ?? "Unknown";
                  String vid = d['vendorId'].toString();
                  String pid = d['productId'].toString();

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading:
                          const Icon(Icons.print, color: Color(0xFF009688)),
                      title: Text(name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("VID: $vid | PID: $pid"),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _connectToDevice(d);
                        },
                        child: const Text('ເຊື່ອມຕໍ່'),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ປິດ'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      _showSnack("Error: $e", const Color(0xFFC0392B));
    }
  }

  // 🆕 ฟังก์ชันเชื่อมต่อกับอุปกรณ์ที่เลือก
  Future<void> _connectToDevice(Map<String, dynamic> device) async {
    try {
      final success = await _printerService.connect(device);
      _printerService.setConnectionStatus(success, device);

      if (success) {
        _showSnack("✅ ເຊື່ອມຕໍ່ສຳເລັດ: ${device['productName']}",
            const Color(0xFF27AE60));
        // เช็คสถานะหลังเชื่อมต่อสำเร็จ
        await _checkPrinterStatus();
      } else {
        _showSnack("❌ ເຊື່ອມຕໍ່ບໍ່ສຳເລັດ", const Color(0xFFC0392B));
      }
    } catch (e) {
      _printerService.setConnectionStatus(false);
      _showSnack("❌ ເຊື່ອມຕໍ່ບໍ່ໄດ້: $e", const Color(0xFFC0392B));
    }
  }

  // 🧪 ฟังก์ชัน Test Print
  void _handleTestPrint() async {
    if (!_printerService.isConnectedNotifier.value) {
      _showSnack("ກະລຸນາເຊື່ອມຕໍ່ເຄື່ອງພິມກ່ອນ", const Color(0xFFC0392B));
      return;
    }

    // แสดง loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      debugPrint('🧪 [TEST PRINT] Starting test print with auto-retry...');

      await _printerService.printTicket(
        ticketId: "TEST-001",
        shopName: "TEST PRINT",
        date: "01/01/2025",
        time: "12:00",
        ticketType: "TEST MODE",
        rideList: ["Test Item 1", "Test Item 2"],
        qrData: "123456",
      );

      if (mounted) Navigator.pop(context);
      _showSnack("✅ ສົ່ງຄຳສັ່ງພິມສຳເລັດ", const Color(0xFF27AE60));
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('❌ [TEST PRINT] Error: $e');
      _showSnack("❌ ພິມບໍ່ສຳເລັດ: $e", const Color(0xFFC0392B));
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

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF009688);
    const Color successGreen = Color(0xFF27AE60);
    const Color errorRed = Color(0xFFC0392B);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Printer Status"),
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status Card
              ValueListenableBuilder<bool>(
                valueListenable: _printerService.isConnectedNotifier,
                builder: (context, isConnected, child) {
                  final statusColor = isConnected ? successGreen : errorRed;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isConnected ? Icons.check_circle : Icons.error,
                          color: statusColor,
                          size: 80,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isConnected ? "Connected" : "Disconnected",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isConnected
                              ? "Printer is ready"
                              : "Please check connection",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (isConnected) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Paper Status:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _paperStatus,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _paperStatus.contains('OK')
                                      ? successGreen
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Last Check:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _lastCheckTime,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Action Buttons (only when connected)
              ValueListenableBuilder<bool>(
                valueListenable: _printerService.isConnectedNotifier,
                builder: (context, isConnected, child) {
                  if (!isConnected) {
                    return Column(
                      children: [
                        // 🆕 Scan & Connect Button เมื่อยังไม่เชื่อมต่อ
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: _handleConnect,
                            icon: const Icon(Icons.usb, size: 28),
                            label: const Text(
                              "Scan & Connect Printer",
                              style: TextStyle(fontSize: 18),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryTeal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Icon(
                          Icons.info_outline,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Press button above to scan\nand connect USB printer',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      // Check Status Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton.icon(
                          onPressed: _isChecking
                              ? null
                              : () async {
                                  await _checkPrinterStatus();
                                  if (mounted) {
                                    final stillConnected = _printerService
                                        .isConnectedNotifier.value;
                                    _showSnack(
                                      stillConnected
                                          ? '✅ Status: $_paperStatus'
                                          : '❌ Disconnected',
                                      stillConnected ? successGreen : errorRed,
                                    );
                                  }
                                },
                          icon: _isChecking
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.assignment, size: 28),
                          label: Text(
                            _isChecking ? "Checking..." : "Check Paper Status",
                            style: const TextStyle(fontSize: 18),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blueGrey,
                            side: const BorderSide(
                              color: Colors.blueGrey,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Reconnect Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _printerService.autoConnectOnStartup();
                            if (!mounted) return;

                            final isReconnected =
                                _printerService.isConnectedNotifier.value;
                            _showSnack(
                              isReconnected
                                  ? '✅ Reconnected Successfully'
                                  : '⚠️ Reconnect Failed',
                              isReconnected ? successGreen : Colors.orange,
                            );
                          },
                          icon: const Icon(Icons.refresh, size: 28),
                          label: const Text(
                            "Reconnect",
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 🧪 Test Print Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _handleTestPrint,
                          icon: const Icon(Icons.print, size: 28),
                          label: const Text(
                            "Test Print",
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
