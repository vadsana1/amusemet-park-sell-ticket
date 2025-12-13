import 'package:flutter/foundation.dart';

class PrinterService {
  // --- Singleton Pattern ---
  // ให้มั่นใจว่ามี Instance ของ Service นี้เพียงอันเดียวทั่วทั้งแอป
  static final PrinterService _instance = PrinterService._internal();

  factory PrinterService() {
    return _instance;
  }

  PrinterService._internal();

  // --- State Management: ValueNotifier ---
  // ตัวจัดการสถานะที่แจ้งเตือนไปยัง Widgets อื่นๆ
  // ค่าเริ่มต้นคือ false (ยังไม่เชื่อมต่อ)
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);

  // --- 1. ฟังก์ชันอัปเดตสถานะ (เรียกใช้ในหน้า Config) ---
  // ฟังก์ชันนี้จะถูกเรียกเมื่อมีการเชื่อมต่อ/ตัดการเชื่อมต่อสำเร็จ
  void setConnectionStatus(bool isConnected, [dynamic device]) {
    // เช็คว่าสถานะมีการเปลี่ยนแปลงหรือไม่ ก่อนทำการอัปเดต
    if (isConnectedNotifier.value != isConnected) {
      isConnectedNotifier.value = isConnected;
      print('✅ PRINTER SERVICE: Status changed to $isConnected');
    }
  }

  // --- 2. ฟังก์ชันจำลองการเชื่อมต่อ (เรียกใช้ในหน้า Config) ---
  Future<bool> connectToPrinter(dynamic device) async {
    // TODO: ใส่ Logic การเชื่อมต่อ TSC จริงๆ ที่นี่
    // เช่น: final result = await TscSdk.connect(device);

    setConnectionStatus(true, device);
    return true;
  }

  // --- 3. ฟังก์ชันเช็คสถานะปัจจุบัน ---
  bool isConnected() {
    return isConnectedNotifier.value;
  }
}
