// [ FILE: lib/screen/receipt_page.dart ]

import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// --- เพิ่ม Imports สำหรับการ Capture Widget ---
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
// ----------------------------------------------

// 1. Import Model และ Service
import '../models/api_ticket_response.dart';
import '../services/receipt_printer_service.dart'; // ของ iMin (ใบเสร็จการเงิน)
import '../services/sticker_printer_service.dart'; // ของเครื่องปริ้นสติกเกอร์ (ตั๋วเข้าชม)

class ReceiptPage extends StatefulWidget {
  final List<ApiTicketResponse> responses;

  const ReceiptPage({super.key, required this.responses});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  static const bool _isIminEnabled = true;

  // 🟢 [1] Global Key List: สำหรับจับภาพ Widget ตั๋วแต่ละใบ
  final Map<int, GlobalKey> _ticketKeys = {};

  // Service สำหรับการพิมพ์
  final ReceiptPrinterService _iminService =
      ReceiptPrinterService(); // จัดการ iMin
  final StickerPrinterService _ticketService =
      StickerPrinterService.instance; // จัดการ Sticker Printer (ใช้ instance)

  // Storage สำหรับดึงชื่อผู้ขาย
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _sellerName = 'Loading...';

  // Formatters
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

    // 🟢 [2] สร้าง GlobalKey สำหรับตั๋วทุกใบใน Responses
    for (int i = 0; i < widget.responses.length; i++) {
      _ticketKeys[i] = GlobalKey();
    }

    // เช็คก่อน Init เครื่อง iMin ถ้าปิดอยู่ให้ข้ามไปเลย (กันค้างบน Emulator)
    if (_isIminEnabled) {
      _initIminPrinter();
    } else {
      log("Skipped iMin Init (Emulator Mode)");
    }
  }

  Future<void> _loadSellerName() async {
    final userName = await _storage.read(key: 'user_name');
    if (mounted) {
      setState(() {
        _sellerName = userName ?? 'N/A';
      });
    }
  }

  Future<void> _initIminPrinter() async {
    await _iminService.initPrinter();
  }

  // ---------------------------------------------------------------------------
  // Core Capture Logic
  // ---------------------------------------------------------------------------

  // 🟢 [3] ฟังก์ชันสำหรับจับภาพ Widget ด้วย Global Key
  Future<Uint8List?> _captureWidgetToBytes(int index) async {
    final GlobalKey? key = _ticketKeys[index];
    if (key == null || key.currentContext == null) {
      log('Error: Capture key or context not found for index $index.');
      return null;
    }

    try {
      // ให้แน่ใจว่า Widget ถูกวาดเสร็จก่อนจับภาพ
      await Future.microtask(() {});

      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // 🚨 ใช้ pixelRatio สูง (เช่น 3.0) เพื่อให้ภาพคมชัดขึ้นเมื่อย่อพิมพ์
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return null;
      return byteData.buffer.asUint8List();
    } catch (e) {
      log('Error capturing widget at index $index: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Event Handlers
  // ---------------------------------------------------------------------------

  void _handlePrintAndClose() async {
    log("Starting dual print job...");

    // =========================================================================
    // ส่วนที่ 1: เครื่อง iMin (พิมพ์ใบเสร็จรับเงิน)
    // =========================================================================
    if (_isIminEnabled) {
      try {
        log("Printing Financial Receipt to iMin...");
        await _iminService.printFinancialReceipt(
          widget.responses.first,
          _sellerName,
        );
      } catch (e) {
        log("Error Printing to iMin: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('iMin Error: $e')));
        }
      }
    } else {
      log("Skipped iMin Printing (Emulator Mode)");
    }

    // =========================================================================
    // 🟢 [4] ส่วนที่ 2: เครื่อง Sticker Printer (พิมพ์รูปภาพตั๋ว)
    // =========================================================================
    try {
      log("Starting capture and print job for ${widget.responses.length} tickets...");

      for (int i = 0; i < widget.responses.length; i++) {
        log("Capturing and printing ticket ${i + 1}/${widget.responses.length}...");

        // 1. จับภาพ Widget เป็น Bytes
        final Uint8List? imageBytes = await _captureWidgetToBytes(i);

        if (imageBytes != null) {
          // 2. สั่งพิมพ์รูปภาพทั้งใบ (โดยใช้ฟังก์ชันใน Service)
          // ใช้ 0, 0 เพื่อให้ภาพเริ่มพิมพ์ที่มุมซ้ายบนของสติกเกอร์
          await _ticketService.printImageFile(
            imageBytes,
            x: 0,
            y: 0,
            maxWidthDots: 480,
          );

          // หน่วงเวลาเพื่อให้เครื่องพิมพ์ประมวลผล Bitmap ก่อนใบถัดไป
          await Future.delayed(const Duration(milliseconds: 700));
        } else {
          log("Skipped printing ticket ${i + 1}: Failed to capture image.");
        }
      }

      log("Sticker print job complete.");
    } catch (e) {
      log("Printing Tickets Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ticket Print Error: $e')));
      }
    }

    log("Print job complete.");

    // ปิดหน้าจอเมื่อทำงานเสร็จ
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
              // UI: ใบสรุปการเงิน (ยังคงเดิม)
              _buildFinancialReceipt(financialResponse),
              const SizedBox(height: 24),
              // UI: ตั๋วทั้งหมด (แก้ไข Layout ภายใน)
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
  // UI Builder Widgets
  // ---------------------------------------------------------------------------

  Widget _buildTicketStubsWrap(List<ApiTicketResponse> responses) {
    final List<ApiTicketResponse> ticketStubs = responses;
    if (ticketStubs.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 12,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: ticketStubs.asMap().entries.map((entry) {
              final int index = entry.key;
              final ApiTicketResponse response = entry.value;
              return _buildTicketStub(response, index);
            }).toList(),
          ),
        );
      },
    );
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

  // ===========================================================================
  // 🟢 Ticket Stub (เพิ่ม GlobalKey สำหรับ Capture)
  // ===========================================================================
  Widget _buildTicketStub(ApiTicketResponse response, int index) {
    final DateTime now = DateTime.now();
    final String dateString = dateFormat.format(now);
    final String timeString = timeFormat.format(now);

    String ticketTypeString;
    String countString;
    if (response.adultCount >= 1) {
      ticketTypeString = 'ຜູ້ໃຫຍ່ (Adult)';
      countString = '${response.adultCount}';
    } else if (response.childCount >= 1) {
      ticketTypeString = 'ເດັກນ້ອຍ (Child)';
      countString = '${response.childCount}';
    } else {
      ticketTypeString = 'N/A';
      countString = '1';
    }

    return RepaintBoundary(
      // 🟢 1. ครอบด้วย RepaintBoundary
      key: _ticketKeys[index], // 🟢 2. ผูก GlobalKey
      child: Container(
        width: 480, // match printable width for 60mm label (~480 dots @203dpi)
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------
            // [LEFT COLUMN] : ວັນທີ, ເລກທີ, QR Code
            // -------------------------------------------------------
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. ວັນທີ & ເວລາ
                  Text(
                    'ວັນທີ: $dateString',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  Text(
                    'ເວລາ: $timeString',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),

                  const SizedBox(height: 12), // ໄລຍະຫ່າງ
                  // 2. ເລກທີປີ້
                  Text(
                    'ເລກທີ: ${response.purchaseId}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. QR Code (ຈັດກາງใน Column ຊ້າຍ)
                  Center(
                    child: SizedBox(
                      height: 140,
                      width: 140,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: _buildQrCode(response.qrCode),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Divider(color: Colors.black26),

                  // 4. ປະເພດປີ້
                  Center(
                    child: Text(
                      '$ticketTypeString x $countString ຈຳນວນ',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16), // ຊ່ອງວ່າງລະຫວ່າງຊ້າຍ-ຂວາ
            // -------------------------------------------------------
            // [RIGHT COLUMN] : Laodoove, ຫົວຂໍ້, ຕາຕະລາງ
            // -------------------------------------------------------
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  // 1. ຊື່ຮ້ານ Laodoove (ຊິດຂວາ)
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Laodoove',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  // 🔥 ໄລຍະຫ່າງນ້ອຍໆ ເພື່ອໃຫ້ຕາຕະລາງດຶງຂຶ້ນມາຕິດກັບຊື່ຮ້ານເລີຍ
                  const SizedBox(height: 20),

                  // 2. ຫົວຂໍ້ປະເພດເຄື່ອງຫຼິ້ນ
                  const Text(
                    'ປະເພດເຄື່ອງຫຼິ້ນ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // 3. ຕາຕະລາງ
                  _buildRideTable(response.rideNames),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🟢 Helper Widgets ສຳລັບຕາຕະລາງເຄື່ອງຫຼິ້ນ
  // ---------------------------------------------------------------------------
  Widget _buildRideTable(List<String> rideNames) {
    if (rideNames.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.black)),
        child: const Center(child: Text('ບໍ່ມີເຄື່ອງຫຼິ້ນ')),
      );
    }

    // 1. ຄຳນວນການແບ່ງເຄິ່ງ (Dynamic Split)
    final int halfIndex = (rideNames.length / 2).ceil();

    final List<String> col1 = rideNames.sublist(0, halfIndex);
    final List<String> col2 = rideNames.sublist(halfIndex);

    // 2. ຕື່ມຊ່ອງວ່າງໃສ່ຖັນທີ 2 ໃຫ້ຈຳນວນແຖວເທົ່າກັນ (ເພື່ອຄວາມສວຍງາມ)
    while (col2.length < col1.length) {
      col2.add('');
    }

    return Container(
      decoration: BoxDecoration(
        // ขอบตารางสีดำ
        border: Border.all(color: Colors.black, width: 1.0),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- ຖັນທີ 1 (ซ้าย) ---
            Expanded(child: _buildRideColumn(col1)),

            // --- ເສັ້ນຂັ້ນກາງ ---
            const VerticalDivider(
              color: Colors.black,
              thickness: 1.0,
              width: 1,
            ),

            // --- ຖັນທີ 2 (ขวา) ---
            Expanded(child: _buildRideColumn(col2)),
          ],
        ),
      ),
    );
  }

  Widget _buildRideColumn(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        // ถ้าเป็นช่องว่าง (ที่ add เข้าไปให้เต็ม)
        if (item.isEmpty) return const SizedBox(height: 22);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: const BoxDecoration(
              // (Optional)
              ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // จัดชิดบน
            children: [
              // ວົງມົນ (Bullet)
              Padding(
                padding: const EdgeInsets.only(
                  top: 3,
                ), // ขยับวงกลมลงนิดหน่อย
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.2),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // ชื่องเครื่องเล่น
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                  softWrap: true,
                  maxLines: 2, // แสดงสูงสุด 2 บรรทัด
                  overflow: TextOverflow.ellipsis, // ถ้ายาวเกินให้แสดง ...
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // General Helpers
  // ---------------------------------------------------------------------------

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
              // Header แบบเดิม (สำหรับ Financial Receipt ຫາກຕ້ອງການ)
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
    // ถ้า API ส่งมาเป็น SVG Base64 ก็แสดงผล
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
      return Text('QR Data: $qrData');
    }
  }
}
