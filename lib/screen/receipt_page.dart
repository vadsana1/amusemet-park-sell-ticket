// [ FILE: receipt_page.dart ]

import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 1. Import Model และ Service
import '../models/api_ticket_response.dart';
import '../services/receipt_printer_service.dart'; // 👈 Import Service

class ReceiptPage extends StatefulWidget {
  final List<ApiTicketResponse> responses;

  const ReceiptPage({super.key, required this.responses});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  // ---------------------------------------------------------------------------
  // State Variables & Services
  // ---------------------------------------------------------------------------
  
  // Service สำหรับการพิมพ์
  final ReceiptPrinterService _printerService = ReceiptPrinterService();

  // Storage สำหรับดึงชื่อผู้ขาย
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _sellerName = 'Loading...';

  // Formatters (เก็บไว้สำหรับ UI)
  final currencyFormat = NumberFormat("#,##0", "en_US");
  final dateFormat = DateFormat('dd/MM/yyyy');
  final timeFormat = DateFormat('HH:mm');

  // ---------------------------------------------------------------------------
  // Init & Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadSellerName();
    _initPrinter(); // เรียก init Printer จาก Service
  }

  /// ดึงชื่อผู้ขายจาก Secure Storage
  Future<void> _loadSellerName() async {
    final userName = await _storage.read(key: 'user_name');
    if (mounted) {
      setState(() {
        _sellerName = userName ?? 'N/A';
      });
    }
  }

  /// เตรียมความพร้อมเครื่องพิมพ์ผ่าน Service
  Future<void> _initPrinter() async {
    await _printerService.initPrinter();
  }

  // ---------------------------------------------------------------------------
  // Event Handlers
  // ---------------------------------------------------------------------------

  /// จัดการการกดปุ่ม "พิมพ์"
  void _handlePrintAndClose() async {
    try {
      log("Starting print job (via Service)...");

      // 1. พิมพ์ใบสรุปการเงิน
      await _printerService.printFinancialReceipt(
        widget.responses.first,
        _sellerName, // ส่งชื่อผู้ขายไปให้ Service
      );

      // 2. Loop พิมพ์ตั๋ว QR
      for (var response in widget.responses) {
        await _printerService.printTicketStub(
          response,
          _sellerName, // ส่งชื่อผู้ขายไปให้ Service
        );
      }

      log("Print job complete.");
    } catch (e) {
      log("Printing Error: $e");
    }

    // 3. ปิดหน้าจอเมื่อพิมพ์เสร็จ
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  // ---------------------------------------------------------------------------
  // Build Method (UI)
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (widget.responses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('ບໍ່ພົບຂໍ້ມູນໃບຮັບເງິນ')),
      );
    }

    // ข้อมูลสำหรับใบสรุปการเงิน (ใบแรก)
    final ApiTicketResponse financialResponse = widget.responses.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ໃບຮັບເງິນ (Receipt)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
      backgroundColor: Colors.grey[300],
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // UI: ใบสรุปการเงิน
              _buildFinancialReceipt(financialResponse),

              const SizedBox(height: 24),

              // UI: ตั๋วทั้งหมด
              _buildTicketStubsWrap(widget.responses),

              const SizedBox(height: 24),
              
              // UI: ปุ่มพิมพ์
              _buildPrintButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI Builder Widgets (โค้ดส่วน UI ทั้งหมดเหมือนเดิม)
  // ---------------------------------------------------------------------------

  Widget _buildTicketStubsWrap(List<ApiTicketResponse> responses) {
    final List<ApiTicketResponse> ticketStubs = responses;

    if (ticketStubs.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        width: constraints.maxWidth,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Wrap(
          spacing: 12,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: ticketStubs.map((ticketResponse) {
            return _buildTicketStub(ticketResponse);
          }).toList(),
        ),
      );
    });
  }

  Widget _buildFinancialReceipt(ApiTicketResponse response) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(response, isFinancialReceipt: true),
          const SizedBox(height: 16),
          _buildInfoRow(
            'ລາຄາທັງໝົດ:',
            '${currencyFormat.format(response.amountDue)} ກີບ',
            isBold: true,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'ເງິນທີ່ໄດ້ຮັບ:',
            '${currencyFormat.format(response.amountPaid)} ກີບ',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'ເງິນທອນ:',
            '${currencyFormat.format(response.changeAmount)} ກີບ',
          ),
        ],
      ),
    );
  }

  Widget _buildTicketStub(ApiTicketResponse response) {
    String ticketTypeString;
    if (response.adultCount == 1) {
      ticketTypeString = 'ຜູ້ໃຫຍ່ (Adult)';
    } else if (response.childCount == 1) {
      ticketTypeString = 'ເດັກນ້ອຍ (Child)';
    } else {
      ticketTypeString = 'N/A';
    }

    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(
            child: Text(
              'ປີ້ສຳລັບເຂົ້າເຄື່ອງຫຼິ້ນ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          _buildHeader(response, isFinancialReceipt: false),
          const SizedBox(height: 16),
          _buildInfoRow(
            'ປະເພດປີ້:',
            ticketTypeString,
          ),
          const Divider(height: 32, thickness: 1),
          Center(child: _buildQrCode(response.qrCode)),
          const Divider(height: 32, thickness: 1),
          const Text(
            'ປະເພດເຄື່ອງຫຼິ້ນ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRideList(response.rideNames),
        ],
      ),
    );
  }

  Widget _buildPrintButton() {
    return Container(
      width: 400,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A9A8B),
          minimumSize: const Size(double.infinity, 50),
          textStyle: const TextStyle(fontSize: 16, fontFamily: 'Phetsarath_OT'),
        ),
        onPressed: _handlePrintAndClose,
        child: const Text('ພິມ ແລະ ສຳເລັດ'),
      ),
    );
  }

  Widget _buildRideList(List<String> rideNames) {
    if (rideNames.isEmpty) {
      return const Text(
        'ບໍ່ມີເຄື່ອງຫຼິ້ນທີ່ເລືອກ',
        style: TextStyle(fontSize: 16),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rideNames.map((rideName) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(rideName, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 8),
              const Text('O', style: TextStyle(fontSize: 16)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeader(
    ApiTicketResponse response, {
    required bool isFinancialReceipt,
  }) {
    final DateTime now = DateTime.now();
    final String dateString = dateFormat.format(now);
    final String timeString = timeFormat.format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFinancialReceipt)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ເລກທີໃບບິນ: ${response.purchaseId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ຜູ້ຂາຍ: $_sellerName',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'ID ປີ້: ${response.purchaseId}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'ວັນທີ: $dateString',
                  style: const TextStyle(fontSize: 16),
                ),
                Text('ເວລາ: $timeString', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
        if (!isFinancialReceipt)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'ຜູ້ຂາຍ: $_sellerName',
              style: const TextStyle(fontSize: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.red[700] : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildQrCode(String qrData) {
    if (qrData.isEmpty) {
      return const Text('ບໍ່ສາມາດສ້າງ QR Code ໄດ້');
    }

    if (qrData.startsWith('data:image/svg+xml;base64,')) {
      try {
        String base64String = qrData.split(',').last;
        String svgString = utf8.decode(base64Decode(base64String));
        return SvgPicture.string(svgString, width: 250, height: 250);
      } catch (e) {
        log("Error decoding SVG: $e");
        return Text('Error displaying QR: $e');
      }
    } else {
      return Text('QR Data (Non-SVG): $qrData');
    }
  }
} // End of _ReceiptPageState