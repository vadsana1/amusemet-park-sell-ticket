import 'dart:convert'; // [เพิ่ม] 1. สำหรับถอดรหัส Base64
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// [เพิ่ม] 2. Import package SVG
import 'package:flutter_svg/flutter_svg.dart';
// [แก้ไข] 3. Import Response Model ใหม่
import '../models/api_ticket_response.dart';

class ReceiptPage extends StatelessWidget {
  // [แก้ไข] 4. รับ "Response"
  final ApiTicketResponse response;

  const ReceiptPage({super.key, required this.response});

  // [เพิ่ม] 5. ฟังก์ชัน Helper สำหรับถอดรหัสและแสดง QR
  Widget _buildQrCodeWidget(String base64SvgData) {
    try {
      // 5a. ตรวจสอบว่ามี "header" (data:image/svg+xml;base64,) หรือไม่
      if (base64SvgData.startsWith('data:image/svg+xml;base64,')) {
        // 5b. แยกเอาเฉพาะข้อมูล Base64 (ส่วนที่อยู่หลัง comma)
        final String base64String = base64SvgData.split(',').last;

        // 5c. ถอดรหัส Base64 ให้เป็น String (XML)
        final String svgXmlString = utf8.decode(base64Decode(base64String));

        // 5d. แสดงผลด้วย SvgPicture.string
        return SvgPicture.string(svgXmlString, width: 220, height: 220);
      } else {
        // ถ้า API ส่งมาไม่ตรงรูปแบบ
        return const Text('Error: Invalid QR code format');
      }
    } catch (e) {
      // ถ้าถอดรหัสไม่ได้
      print('Error decoding Base64 SVG: $e');
      return const Text('Error displaying QR code');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "en_US");

    return Scaffold(
      appBar: AppBar(
        title: const Text('ການດຳເນີນການສຳເລັດ'),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1A9A8B),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- [แก้ไข] 6. เรียกใช้ฟังก์ชันแสดง QR Code ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _buildQrCodeWidget(
                  response.qrCode,
                ), // <-- ใช้ response.qrCode
              ),

              // --- [สิ้นสุดการแก้ไข] ---
              const SizedBox(height: 24),
              const Text(
                'ອອກປີ້ສຳເລັດ', // 'ออกตั๋วสำเร็จ'
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              Text(
                response.message, // [เพิ่ม] แสดง Message จาก API
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                'ID: ${response.purchaseId}', // [แก้ไข]
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                'UID: ${response.visitorUid}', // [แก้ไข]
                style: const TextStyle(fontSize: 18),
              ),
              const Divider(height: 48),

              SizedBox(
                width: 300,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A9A8B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    'ຕົກລົງ (ກັບໄປໜ້າຫຼັກ)', // ตกลง (กลับไปหน้าหลัก)
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
