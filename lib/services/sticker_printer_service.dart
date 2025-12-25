// [ FILE: lib/services/sticker_printer_service.dart ]

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

Uint8List _convertToTsplMonochrome(Map<String, dynamic> data) {
  final img.Image monoImage = data['image'];
  final int widthBytes = data['widthBytes'];
  final int imageWidth = data['imageWidth'];
  final int imageHeight = data['imageHeight'];
  final int threshold = data['threshold'] ?? 180;
  final bool invert = data['invert'] ?? false;

  Uint8List bitmapBytes = Uint8List(widthBytes * imageHeight);
  int byteIndex = 0;

  for (int yCoord = 0; yCoord < imageHeight; yCoord++) {
    int byte = 0;
    int bitPosition = 0;
    for (int xCoord = 0; xCoord < imageWidth; xCoord++) {
      final img.Pixel pixel = monoImage.getPixel(xCoord, yCoord);
      final int colorValue = pixel.r.toInt();

      bool isBlack = colorValue < threshold;
      if (invert) isBlack = !isBlack;

      if (isBlack) {
        byte |= (1 << (7 - bitPosition));
      }

      bitPosition++;
      if (bitPosition == 8) {
        bitmapBytes[byteIndex++] = byte;
        byte = 0;
        bitPosition = 0;
      }
    }
    if (bitPosition > 0) {
      bitmapBytes[byteIndex++] = byte;
    }
  }
  return bitmapBytes;
}

// ------------------------------------------------------------------
//  CLASS DEFINITION
// ------------------------------------------------------------------
class StickerPrinterService {
  // --- Singleton Pattern ---
  StickerPrinterService._privateConstructor();
  static final StickerPrinterService instance =
      StickerPrinterService._privateConstructor();

  final FlutterUsbPrinter _printer = FlutterUsbPrinter();

  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);

  // 🆕 Notifier สำหรับแจ้งเตือนเมื่อต้องการให้เชื่อมต่อใหม่
  final ValueNotifier<bool> needsReconnectNotifier = ValueNotifier<bool>(false);

  Map<String, dynamic>? _connectedDevice;
  Timer? _connectionCheckTimer;

  void setConnectionStatus(bool isConnected, [Map<String, dynamic>? device]) {
    if (isConnectedNotifier.value != isConnected) {
      isConnectedNotifier.value = isConnected;
    }
    _connectedDevice = isConnected ? device : null;
    debugPrint(
        'SERVICE STATUS UPDATED: ${isConnected ? "CONNECTED" : "DISCONNECTED"}');

    // 🆕 เมื่อเชื่อมต่อสำเร็จ เริ่มตรวจสอบการเชื่อมต่อแบบ periodic
    if (isConnected) {
      startConnectionMonitoring();
    } else {
      stopConnectionMonitoring();
    }
  }

  // 🆕 เริ่มตรวจสอบการเชื่อมต่อแบบ periodic
  void startConnectionMonitoring() {
    stopConnectionMonitoring(); // หยุด timer เก่าก่อน

    _connectionCheckTimer = Timer.periodic(
      const Duration(
          seconds: 3), // ⚡ ตรวจสอบทุก 3 วินาที เพื่อตรวจจับการถอดสายได้เร็วขึ้น
      (timer) async {
        await _checkConnectionPeriodically();
      },
    );
    debugPrint('🔄 Started connection monitoring (every 3s)');
  }

  // 🆕 หยุดตรวจสอบการเชื่อมต่อ
  void stopConnectionMonitoring() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
    debugPrint('🛑 Stopped connection monitoring');
  }

  // 🆕 ตรวจสอบการเชื่อมต่อแบบ periodic
  Future<void> _checkConnectionPeriodically() async {
    // ถ้าไม่เคยเชื่อมต่อเลย ให้ตรวจจับว่ามีอุปกรณ์ที่เคยเชื่อมต่อเสียบเข้ามาหรือไม่
    if (_connectedDevice == null) {
      await _checkForReconnectedDevice();
      return;
    }

    // ตรวจสอบว่าอุปกรณ์ยังอยู่ใน USB list หรือไม่ (ไม่ส่งคำสั่ง เพราะจะทำให้ connection fail)
    try {
      final devices = await scanDevices();
      final matchedDevice = devices.firstWhere(
        (d) =>
            d['vendorId'].toString() ==
                _connectedDevice!['vendorId'].toString() &&
            d['productId'].toString() ==
                _connectedDevice!['productId'].toString(),
        orElse: () => {},
      );

      if (matchedDevice.isEmpty && isConnectedNotifier.value) {
        // อุปกรณ์ถูกถอดออก
        debugPrint('⚠️ USB Device disconnected - not in device list');
        setConnectionStatus(false);
        needsReconnectNotifier.value = true; // แจ้งให้ reconnect
      } else if (matchedDevice.isNotEmpty) {
        // เช็คว่า deviceId เปลี่ยนหรือไม่ (หลังจากถอด-เสียบใหม่)
        final oldDeviceId = _connectedDevice!['deviceId']?.toString();
        final newDeviceId = matchedDevice['deviceId']?.toString();

        if (oldDeviceId != null &&
            newDeviceId != null &&
            oldDeviceId != newDeviceId) {
          debugPrint(
              '⚠️ Device ID changed: $oldDeviceId → $newDeviceId (USB re-plugged)');
          debugPrint(
              '❌ Connection is STALE - disconnecting and notifying user');

          // Disconnect แล้วให้ user reconnect manually เพื่อความแน่ใจ
          await disconnect();
          needsReconnectNotifier.value = true; // แจ้งให้ UI แสดง dialog
        } else if (!isConnectedNotifier.value) {
          // อุปกรณ์เสียบกลับมา (และเรายังไม่ได้เชื่อมต่อ)
          debugPrint('✅ USB Device reconnected - notifying user');
          needsReconnectNotifier.value = true; // แจ้งให้ UI แสดง dialog
        }
      }
    } catch (e) {
      debugPrint('Connection check error: $e');
      // ถ้า scan devices error และสถานะยังบอกว่าเชื่อมต่อ ให้เปลี่ยนเป็น disconnected
      if (isConnectedNotifier.value) {
        debugPrint('⚠️ Scan failed - assuming disconnected');
        setConnectionStatus(false);
      }
    }
  }

  // 🆕 ตรวจจับว่ามีอุปกรณ์ที่เคยเชื่อมต่อเสียบเข้ามาหรือไม่
  Future<void> _checkForReconnectedDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastVid = prefs.getString('tsc_last_vid');
      final String? lastPid = prefs.getString('tsc_last_pid');

      if (lastVid == null || lastPid == null) return;

      final devices = await scanDevices();
      final match = devices.firstWhere(
        (d) =>
            d['vendorId'].toString() == lastVid &&
            d['productId'].toString() == lastPid,
        orElse: () => {},
      );

      if (match.isNotEmpty && !isConnectedNotifier.value) {
        // พบอุปกรณ์ที่เคยเชื่อมต่อ และยังไม่ได้เชื่อมต่อ
        debugPrint('✅ Previously connected device found - notifying user');

        // 🔧 เพิ่มชื่อสำรองถ้า productName เป็น null
        if (match['productName'] == null ||
            match['productName'].toString().isEmpty) {
          match['productName'] = 'USB Printer (VID:$lastVid PID:$lastPid)';
        }

        _connectedDevice = match; // เก็บข้อมูลอุปกรณ์ไว้
        needsReconnectNotifier.value = true;
      }
    } catch (e) {
      debugPrint('Check for reconnected device error: $e');
    }
  }

  // 🆕 รีเซ็ต needsReconnect flag
  void clearReconnectFlag() {
    needsReconnectNotifier.value = false;
  }

  // 🆕 ดึงข้อมูลอุปกรณ์ที่เชื่อมต่ออยู่
  Map<String, dynamic>? getConnectedDeviceInfo() {
    return _connectedDevice;
  }

  Future<bool> checkConnection() async {
    try {
      if (_connectedDevice == null) {
        setConnectionStatus(false);
        return false;
      }

      // ตรวจสอบว่าอุปกรณ์ยังอยู่ใน USB list หรือไม่
      final devices = await scanDevices();
      final matchedDevice = devices.firstWhere(
        (d) =>
            d['vendorId'].toString() ==
                _connectedDevice!['vendorId'].toString() &&
            d['productId'].toString() ==
                _connectedDevice!['productId'].toString(),
        orElse: () => {},
      );

      if (matchedDevice.isEmpty) {
        debugPrint('⚠️ Device not in USB list - disconnected');
        setConnectionStatus(false);
        return false;
      }

      // 🔧 เช็คว่า deviceId เปลี่ยนหรือไม่ (critical check!)
      final oldDeviceId = _connectedDevice!['deviceId']?.toString();
      final newDeviceId = matchedDevice['deviceId']?.toString();

      debugPrint(
          '🔍 Checking deviceId: stored=$oldDeviceId, current=$newDeviceId');

      if (oldDeviceId != null &&
          newDeviceId != null &&
          oldDeviceId != newDeviceId) {
        debugPrint('❌ Device ID MISMATCH: $oldDeviceId → $newDeviceId');
        debugPrint('❌ Connection is STALE - USB was unplugged/replugged!');
        setConnectionStatus(false);
        needsReconnectNotifier.value = true; // แจ้งให้ reconnect
        return false; // connection is invalid!
      }

      // ถ้าอุปกรณ์ยังอยู่ใน list และ deviceId ตรงกัน ถือว่ายังเชื่อมต่ออยู่
      debugPrint('✅ Device still connected (deviceId matches)');
      return true;
    } catch (e) {
      debugPrint('checkConnection error: $e');
      setConnectionStatus(false);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> scanDevices() async {
    try {
      return await FlutterUsbPrinter.getUSBDeviceList();
    } catch (e) {
      debugPrint("Scan Error: $e");
      return [];
    }
  }

  // Auto-connect to last saved device (VID/PID) if available
  Future<void> autoConnectOnStartup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastVid = prefs.getString('tsc_last_vid');
      final String? lastPid = prefs.getString('tsc_last_pid');
      if (lastVid == null || lastPid == null) {
        // 🆕 ถึงแม้ไม่มีอุปกรณ์ที่บันทึกไว้ ก็เริ่ม monitoring เพื่อตรวจจับการเสียบใหม่
        startConnectionMonitoring();
        return;
      }

      final devices = await scanDevices();
      final match = devices.firstWhere(
        (d) =>
            d['vendorId'].toString() == lastVid &&
            d['productId'].toString() == lastPid,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        // 🔧 เพิ่มชื่อสำรองถ้า productName เป็น null (เพื่อแสดงใน permission dialog)
        if (match['productName'] == null ||
            match['productName'].toString().isEmpty) {
          match['productName'] = 'USB Printer (VID:$lastVid PID:$lastPid)';
        }
        await connect(match);
      } else {
        // 🆕 ถ้าไม่พบอุปกรณ์ ให้เริ่ม monitoring เพื่อรอการเสียบ
        startConnectionMonitoring();
      }
    } catch (e) {
      debugPrint('AutoConnect error: $e');
      // 🆕 เริ่ม monitoring แม้เกิด error
      startConnectionMonitoring();
    }
  }

  Future<void> _saveLastDevice(Map<String, dynamic> device) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tsc_last_vid', device['vendorId'].toString());
      await prefs.setString('tsc_last_pid', device['productId'].toString());
      await prefs.setString(
          'tsc_last_name', (device['productName'] ?? '').toString());
    } catch (e) {
      debugPrint('Save last device error: $e');
    }
  }

  Future<bool> connect(Map<String, dynamic> device) async {
    try {
      // 🔍 แสดงข้อมูลอุปกรณ์ที่กำลังพยายามเชื่อมต่อ
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔌 กำลังเชื่อมต่อกับอุปกรณ์:');
      // debugPrint('   📛 ชื่อ: {device['productName'] ?? 'Unknown'}');
      // debugPrint('   ผู้ผลิต: ${device['manufacturer'] ?? 'Unknown'}');
      // debugPrint('   🔢 VID: ${device['vendorId']}');
      // debugPrint('   🔢 PID: ${device['productId']}');
      // debugPrint('   📍 Device: ${device['deviceName']}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Close any existing connection first
      try {
        await _printer.close();
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (closeError) {
        debugPrint('Close previous connection: $closeError');
      }

      // 🔑 เชื่อมต่อโดยตรง (device_filter.xml จะทำให้ Android auto-grant permission)
      final int vid = int.parse(device['vendorId'].toString());
      final int pid = int.parse(device['productId'].toString());

      await _printer.connect(vid, pid);

      setConnectionStatus(true, device);
      // debugPrint('✅ เชื่อมต่อสำเร็จกับ: ${device['productName'] ?? 'Unknown'}');
      // debugPrint('   VID: ${device['vendorId']}, PID: ${device['productId']}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      // persist for auto-connect next time
      await _saveLastDevice(device);
      return true;
    } catch (e) {
      setConnectionStatus(false, null);
      debugPrint("❌ Connection Error: $e");

      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _printer.close();
      setConnectionStatus(false);
      debugPrint('🔌 Disconnected from printer');
    } catch (e) {
      debugPrint('Disconnect error: $e');
      setConnectionStatus(false);
    }
  }

  // 🆕 Restart Connection - ใช้เมื่อ connection มีปัญหา
  Future<bool> restartConnection() async {
    debugPrint('🔄 Restarting connection...');

    if (_connectedDevice == null) {
      debugPrint('❌ No device info to reconnect');
      return false;
    }

    // เก็บ VID/PID ไว้เพื่อค้นหา device ใหม่
    final oldVid = _connectedDevice!['vendorId'].toString();
    final oldPid = _connectedDevice!['productId'].toString();

    // ปิด connection เก่า
    await disconnect();

    // 🔧 รอนานขึ้น เพื่อให้ Android ปล่อย USB resource จริงๆ
    debugPrint('⏳ Waiting for USB resource to be released...');
    await Future.delayed(
        const Duration(milliseconds: 2000)); // เพิ่มจาก 1000 เป็น 2000

    // 🔍 Scan หา device ใหม่จาก USB list (เพื่อได้ deviceId ใหม่)
    debugPrint('🔍 Scanning for device with VID:$oldVid PID:$oldPid...');
    final devices = await scanDevices();
    final freshDevice = devices.firstWhere(
      (d) =>
          d['vendorId'].toString() == oldVid &&
          d['productId'].toString() == oldPid,
      orElse: () => {},
    );

    if (freshDevice.isEmpty) {
      debugPrint('❌ Device not found in USB list');
      return false;
    }

    // debugPrint(
    //     '✅ Found device: ${freshDevice['deviceName']} (deviceId: ${freshDevice['deviceId']})');

    // // 🔧 บังคับให้ plugin close connection เก่าจริงๆ ก่อน connect ใหม่
    try {
      await _printer.close();
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('🧹 Forced plugin to release old connection');
    } catch (e) {
      debugPrint('⚠️ Force close error (ignore): $e');
    }

    // เชื่อมต่อด้วย device info ใหม่
    final success = await connect(freshDevice);

    if (success) {
      debugPrint('✅ Connection restarted successfully with new deviceId');
    } else {
      debugPrint('❌ Failed to restart connection');
    }

    return success;
  }

  // -------------------------------------------------------------------
  Future<void> printTicket({
    required String ticketId,
    required String shopName,
    required String date,
    required String time,
    required String ticketType,
    required List<String> rideList,
    required String qrData,
  }) async {
    if (!isConnectedNotifier.value || _connectedDevice == null) {
      debugPrint("⚠️ Printer not connected - Status shows disconnected");
      throw Exception('Printer not connected - Status shows disconnected');
    }

    // Verify connection before printing
    debugPrint('🔍 Verifying connection before print...');
    final isActuallyConnected = await checkConnection();
    if (!isActuallyConnected) {
      debugPrint("⚠️ Connection verification failed - USB device not found");
      throw Exception('Printer not connected - please reconnect USB cable');
    }
    debugPrint('✅ Connection verified, proceeding to print');

    try {
      String safeQrData = qrData.replaceAll('"', "'");
      List<Uint8List> printData = [];

      // --- TSPL Command Start ---
      printData.add(Uint8List.fromList(utf8.encode("SIZE 60 mm,40 mm\r\n")));
      printData.add(Uint8List.fromList(utf8.encode("GAP 2 mm,0 mm\r\n")));
      printData.add(Uint8List.fromList(utf8.encode("CLS\r\n")));

      int currentY = 10;

      printData.add(Uint8List.fromList(
          utf8.encode("TEXT 10,$currentY,\"3\",0,1,1,\"$shopName\"\r\n")));
      currentY += 30;

      printData.add(Uint8List.fromList(
          utf8.encode("TEXT 240,$currentY,\"2\",1,1,1,\"DATE: $date\"\r\n")));
      currentY += 20;
      printData.add(Uint8List.fromList(
          utf8.encode("TEXT 240,$currentY,\"2\",1,1,1,\"TIME: $time\"\r\n")));

      printData.add(Uint8List.fromList(utf8.encode(
          "TEXT 10,$currentY,\"2\",0,1,1,\"TICKET NO: $ticketId\"\r\n")));

      currentY += 35;

      printData.add(Uint8List.fromList(
          utf8.encode("QRCODE 100,$currentY,L,4,A,0,'$safeQrData'\r\n")));
      printData.add(Uint8List.fromList(utf8.encode("DELAY 100\r\n")));

      currentY += 100;

      currentY += 20;
      printData.add(Uint8List.fromList(utf8
          .encode("TEXT 10,$currentY,\"2\",0,1,1,\"TYPE: $ticketType\"\r\n")));

      printData.add(Uint8List.fromList(
          utf8.encode("TEXT 240,$currentY,\"2\",0,1,1,\"RIDE TYPE\"\r\n")));

      currentY += 35;

      if (rideList.isNotEmpty) {
        String laosHeader = "ລາຍການເຄື່ອງຫຼິ້ນ:";
        List<Uint8List> headerChunks = await _getBitmapChunks(
            laosHeader, 10, currentY,
            isBold: true, fontSize: 18);
        printData.addAll(headerChunks);
        printData.add(Uint8List.fromList(utf8.encode("DELAY 50\r\n")));
        currentY += 28;

        for (String rideName in rideList) {
          List<Uint8List> rideChunks =
              await _getBitmapChunks("- $rideName", 15, currentY, fontSize: 16);
          printData.addAll(rideChunks);
          printData.add(Uint8List.fromList(utf8.encode("DELAY 50\r\n")));
          currentY += 25;
        }
      }

      printData.add(Uint8List.fromList(utf8.encode("PRINT 1,1\r\n")));

      Uint8List finalData =
          Uint8List.fromList(printData.expand((x) => x).toList());

      // 🔄 ลองปริ้นพร้อม retry mechanism
      bool printSuccess = false;
      int retryCount = 0;
      const maxRetries = 2;

      while (!printSuccess && retryCount < maxRetries) {
        try {
          debugPrint(
              '📤 Attempting to print (attempt ${retryCount + 1}/$maxRetries)...');

          bool? success;
          try {
            success = await _printer.write(finalData);
          } catch (pluginError) {
            // Plugin throw exception (เช่น device not exist)
            debugPrint(
                '❌ Plugin exception during write: ${pluginError.toString()}');
            throw Exception('Plugin write error: $pluginError');
          }

          if (success == false || success == null) {
            throw Exception('Printer returned error or null');
          }

          // ตรวจสอบว่า connection ยังใช้ได้หรือไม่หลัง write
          await Future.delayed(const Duration(milliseconds: 200));
          final stillConnected = await checkConnection();

          if (!stillConnected) {
            throw Exception('Connection lost after write');
          }

          printSuccess = true;
          debugPrint("✅ Ticket Print Sent Successfully");
        } catch (writeError) {
          retryCount++;
          debugPrint("❌ Write Error (attempt $retryCount): $writeError");

          if (retryCount < maxRetries) {
            // ลอง reconnect แล้วลองใหม่
            debugPrint(
                '🔄 Attempting auto-reconnect and retry (attempt ${retryCount + 1})...');
            setConnectionStatus(false);

            final reconnected = await restartConnection();

            if (!reconnected) {
              debugPrint('❌ Reconnect failed, stopping retry');
              throw Exception(
                  'Failed to reconnect printer - please reconnect manually');
            }

            debugPrint('✅ Reconnected successfully, retrying print...');
            await Future.delayed(const Duration(milliseconds: 800));
          } else {
            // หมดจำนวนครั้งที่ลองได้
            debugPrint('❌ Max retries reached, print failed');
            setConnectionStatus(false);
            throw Exception(
                'Print failed after $maxRetries attempts - please reconnect manually');
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Print Error: $e");
      setConnectionStatus(false);
      rethrow;
    }
  }

  Future<void> printImageFile(
    Uint8List imageBytes, {
    int x = 0,
    int y = 0,
    int maxWidthDots = 480, // ~60mm at 203dpi
    bool invertColors =
        true, // TSC BITMAP tends to invert; default to invert to keep white bg
    int threshold = 165, // slightly lower threshold to make text darker
  }) async {
    if (!isConnectedNotifier.value || _connectedDevice == null) {
      debugPrint("⚠️ Printer not connected - Status shows disconnected");
      throw Exception('Printer not connected - Status shows disconnected');
    }

    // Verify connection before printing
    debugPrint('🔍 Verifying connection before print...');
    final isActuallyConnected = await checkConnection();
    if (!isActuallyConnected) {
      debugPrint("⚠️ Connection verification failed - USB device not found");
      throw Exception('Printer not connected - please reconnect USB cable');
    }
    debugPrint('✅ Connection verified, proceeding to print');

    try {
      // Load settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final double paperWidth = prefs.getDouble('printer_width') ?? 60.0;
      final double paperHeight = prefs.getDouble('printer_height') ?? 40.0;
      final int darkness = prefs.getDouble('printer_darkness')?.toInt() ?? 12;

      debugPrint(
          '🖨️ Print Settings: Size=${paperWidth}x${paperHeight}mm, Darkness=$darkness');

      List<Uint8List> printData = [];

      // --- TSPL Command Start ---
      printData.add(Uint8List.fromList(
          utf8.encode("SIZE $paperWidth mm,$paperHeight mm\r\n")));
      printData.add(Uint8List.fromList(utf8.encode("GAP 2 mm,0 mm\r\n")));
      // Improve quality: set speed and density for TH240
      printData.add(Uint8List.fromList(utf8.encode("SPEED 3\r\n")));
      printData.add(Uint8List.fromList(utf8.encode("DENSITY $darkness\r\n")));
      printData.add(Uint8List.fromList(utf8.encode("CLS\r\n")));

      List<Uint8List> bitmapChunks = await _getTsplBitmapFromImage(
        imageBytes,
        x,
        y,
        maxWidthDots,
        invertColors,
        threshold,
      );
      printData.addAll(bitmapChunks);

      // --- สั่งพิมพ์ ---
      printData.add(Uint8List.fromList(utf8.encode("PRINT 1,1\r\n")));

      Uint8List finalData =
          Uint8List.fromList(printData.expand((x) => x).toList());

      // Try to write, if it fails, update connection status
      try {
        final bool? success = await _printer.write(finalData);
        if (success == false || success == null) {
          debugPrint("❌ Write failed: Printer returned error or null");
          setConnectionStatus(false);
          throw Exception('Failed to write to printer - check USB connection');
        }

        // ตรวจสอบว่า connection ยังใช้ได้หรือไม่หลัง write
        await Future.delayed(const Duration(milliseconds: 200));
        final stillConnected = await checkConnection();
        if (!stillConnected) {
          debugPrint("❌ Connection lost after write");
          throw Exception('Connection lost during print - please reconnect');
        }

        debugPrint("✅ Image Print Sent Successfully");
      } catch (writeError) {
        debugPrint(
            "❌ Write Error: $writeError - Connection lost, updating status");
        setConnectionStatus(false);
        throw Exception('Print failed: USB connection error - $writeError');
      }
    } catch (e) {
      debugPrint("❌ Image Print Error: $e");
      setConnectionStatus(false);
      rethrow;
    }
  }

  Future<List<Uint8List>> _getTsplBitmapFromImage(
    Uint8List imageBytes,
    int x,
    int y,
    int maxWidthDots,
    bool invertColors,
    int threshold,
  ) async {
    final img.Image? dartImage = img.decodeImage(imageBytes);
    if (dartImage == null) {
      return [
        Uint8List.fromList(
            utf8.encode('TEXT $x,$y,"2",0,1,1,"[IMAGE DECODE ERROR]"'))
      ];
    }

    final img.Image whiteBg = img.Image(
      width: dartImage.width,
      height: dartImage.height,
    );
    img.fill(whiteBg, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(whiteBg, dartImage);

    final img.Image scaledImage = whiteBg.width > maxWidthDots
        ? img.copyResize(whiteBg, width: maxWidthDots)
        : whiteBg;

    final img.Image monoImage = img.grayscale(scaledImage);

    final int imageWidth = monoImage.width;
    final int imageHeight = monoImage.height;
    final int widthBytes = (imageWidth + 7) ~/ 8;

    final Uint8List bitmapBytes = await compute(_convertToTsplMonochrome, {
      'image': monoImage,
      'widthBytes': widthBytes,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'invert': invertColors,
      'threshold': threshold,
    });

    final String bitmapCommand = "BITMAP $x,$y,$widthBytes,$imageHeight,1,";

    return [
      Uint8List.fromList(utf8.encode(bitmapCommand)),
      bitmapBytes,
    ];
  }

  Future<List<Uint8List>> _getBitmapChunks(
    String text,
    int x,
    int y, {
    double fontSize = 16,
    bool isBold = false,
    double maxWidth = 380,
    String fontFamily = 'Phetsarath_OT',
  }) async {
    final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: ui.TextAlign.left,
        fontSize: fontSize,
        fontWeight: isBold ? ui.FontWeight.bold : ui.FontWeight.normal,
        fontFamily: fontFamily,
      ),
    )..addText(text);

    final ui.Paragraph paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: maxWidth));

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final int width = paragraph.longestLine.ceil();
    final int height = paragraph.height.ceil();
    final Rect rect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());

    canvas.drawRect(rect, ui.Paint()..color = Colors.white);
    canvas.drawParagraph(paragraph, Offset(0, 0));

    final ui.Picture picture = recorder.endRecording();
    final ui.Image uiImage = await picture.toImage(width, height);
    final ByteData? byteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return [
        Uint8List.fromList(
            utf8.encode('TEXT $x,$y,"2",0,1,1,"[LAO DRAW ERROR]"'))
      ];
    }

    final img.Image? dartImage = img.decodeImage(byteData.buffer.asUint8List());
    if (dartImage == null) {
      return [
        Uint8List.fromList(
            utf8.encode('TEXT $x,$y,"2",0,1,1,"[LAO DECODE ERROR]"'))
      ];
    }

    final img.Image monoImage = img.grayscale(dartImage);

    final int imageWidth = monoImage.width;
    final int imageHeight = monoImage.height;
    final int widthBytes = (imageWidth + 7) ~/ 8;

    final Uint8List bitmapBytes = await compute(_convertToTsplMonochrome, {
      'image': monoImage,
      'widthBytes': widthBytes,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
    });

    final String bitmapCommand = "BITMAP $x,$y,$widthBytes,$imageHeight,1,";

    return [
      Uint8List.fromList(utf8.encode(bitmapCommand)),
      bitmapBytes,
    ];
  }
}
