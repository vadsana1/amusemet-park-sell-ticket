// [ FILE: lib/services/sticker_printer_service.dart ]

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
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

  Map<String, dynamic>? _connectedDevice;

  void setConnectionStatus(bool isConnected, [Map<String, dynamic>? device]) {
    if (isConnectedNotifier.value != isConnected) {
      isConnectedNotifier.value = isConnected;
    }
    _connectedDevice = isConnected ? device : null;
    debugPrint(
        'SERVICE STATUS UPDATED: ${isConnected ? "CONNECTED" : "DISCONNECTED"}');
  }

  Future<bool> checkConnection() async {
    try {
      if (_connectedDevice == null) {
        setConnectionStatus(false);
        return false;
      }

      final devices = await scanDevices();
      final isStillConnected = devices.any((d) =>
          d['vendorId'].toString() ==
              _connectedDevice!['vendorId'].toString() &&
          d['productId'].toString() ==
              _connectedDevice!['productId'].toString());

      if (!isStillConnected) {
        debugPrint('⚠️ Device disconnected - updating status');
        setConnectionStatus(false);
        return false;
      }

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
      if (lastVid == null || lastPid == null) return;

      final devices = await scanDevices();
      final match = devices.firstWhere(
        (d) =>
            d['vendorId'].toString() == lastVid &&
            d['productId'].toString() == lastPid,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        await connect(match);
      }
    } catch (e) {
      debugPrint('AutoConnect error: $e');
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
      await _printer.connect(
        int.parse(device['vendorId'].toString()),
        int.parse(device['productId'].toString()),
      );

      setConnectionStatus(true, device);
      debugPrint("✅ Connected to ${device['productName']}");
      // persist for auto-connect next time
      await _saveLastDevice(device);
      return true;
    } catch (e) {
      setConnectionStatus(false, null);
      debugPrint("❌ Connection Error: $e");

      return false;
    }
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
      debugPrint("⚠️ Printer not connected");
      return;
    }

    try {
      String safeQrData = qrData.replaceAll('"', "'");
      List<Uint8List> printData = [];

      // --- TSPL Command Start ---
      printData.add(Uint8List.fromList(utf8.encode("SIZE 60 mm,40 mm\r\n")));
      printData.add(Uint8List.fromList(utf8.encode("GAP 2 mm,0 mm\r\n")));
      printData.add(Uint8List.fromList(utf8.encode("CLS\r\n")));

      int currentY = 10;

      printData.add(Uint8List.fromList(
          utf8.encode("TEXT 10,${currentY},\"3\",0,1,1,\"$shopName\"\r\n")));
      currentY += 30;

      printData.add(Uint8List.fromList(
          utf8.encode("TEXT 240,${currentY},\"2\",1,1,1,\"DATE: $date\"\r\n")));
      currentY += 20;
      printData.add(Uint8List.fromList(
          utf8.encode("TEXT 240,${currentY},\"2\",1,1,1,\"TIME: $time\"\r\n")));

      printData.add(Uint8List.fromList(utf8.encode(
          "TEXT 10,${currentY},\"2\",0,1,1,\"TICKET NO: $ticketId\"\r\n")));

      currentY += 35;

      printData.add(Uint8List.fromList(
          utf8.encode("QRCODE 100,${currentY},L,4,A,0,'$safeQrData'\r\n")));
      printData.add(
          Uint8List.fromList(utf8.encode("DELAY 100\r\n")));

      currentY += 100; 

      currentY += 20;
      printData.add(Uint8List.fromList(utf8.encode(
          "TEXT 10,${currentY},\"2\",0,1,1,\"TYPE: $ticketType\"\r\n")));

      printData.add(Uint8List.fromList(
          utf8.encode("TEXT 240,${currentY},\"2\",0,1,1,\"RIDE TYPE\"\r\n")));

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

      try {
        final bool? success = await _printer.write(finalData);
        if (success == false || success == null) {
          debugPrint("❌ Write failed: Printer returned error or null");
          setConnectionStatus(false);
          throw Exception('Failed to write to printer - check USB connection');
        }
        debugPrint("✅ Test Print Sent (TSPL Commands with Lao Bitmap).");
      } catch (writeError) {
        debugPrint("❌ Write Error: $writeError - Connection lost");
        setConnectionStatus(false);
        rethrow;
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
      debugPrint("⚠️ Printer not connected");
      return;
    }

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
        debugPrint("✅ Full Image Sent to TSC Printer.");
      } catch (writeError) {
        debugPrint(
            "❌ Write Error: $writeError - Connection lost, updating status");
        setConnectionStatus(false);
        rethrow;
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
