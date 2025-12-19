// [ FILE: lib/screen/receipt_page.dart ]

import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// --- Add Imports for Widget Capture ---
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
// ----------------------------------------------

// 1. Import Model and Service
import '../models/api_ticket_response.dart';
import '../services/receipt_printer_service.dart'; // for iMin (Financial Receipt)
import '../services/sticker_printer_service.dart'; // for Sticker Printer (Entrance Tickets)

class ReceiptPage extends StatefulWidget {
  final List<ApiTicketResponse> responses;

  const ReceiptPage({super.key, required this.responses});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  static const bool _isIminEnabled = true;

  // 🟢 [1] Global Key List: for capturing each ticket widget
  final Map<int, GlobalKey> _ticketKeys = {};

  // Services for printing
  final ReceiptPrinterService _iminService =
      ReceiptPrinterService(); // manages iMin printer
  final StickerPrinterService _ticketService = StickerPrinterService
      .instance; // manages Sticker Printer (using instance)

  // Storage for retrieving seller name
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

    // 🟢 [2] Create GlobalKey for each ticket in Responses
    for (int i = 0; i < widget.responses.length; i++) {
      _ticketKeys[i] = GlobalKey();
    }

    // Check before Init iMin printer, skip if disabled (prevent hanging on Emulator)
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

  // 🟢 [3] Function to capture Widget as bytes using Global Key
  Future<Uint8List?> _captureWidgetToBytes(int index) async {
    final GlobalKey? key = _ticketKeys[index];
    if (key == null || key.currentContext == null) {
      log('Error: Capture key or context not found for index $index.');
      return null;
    }

    try {
      // Ensure the Widget is fully rendered before capturing
      await Future.microtask(() {});

      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // 🚨 Use high pixelRatio (e.g. 3.0) for sharper image when scaled for printing
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
    // Part 1: iMin Printer (Print Financial Receipt)
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
    // 🟢 [4] Part 2: Sticker Printer (Print Ticket Images)
    // =========================================================================
    try {
      log("Starting capture and print job for ${widget.responses.length} tickets...");

      for (int i = 0; i < widget.responses.length; i++) {
        log("Capturing and printing ticket ${i + 1}/${widget.responses.length}...");

        // 1. Capture Widget as Bytes
        final Uint8List? imageBytes = await _captureWidgetToBytes(i);

        if (imageBytes != null) {
          // 2. Print the entire image (using Service function)
          // Use 0, 0 to start printing from top-left corner of sticker
          await _ticketService.printImageFile(
            imageBytes,
            x: 0,
            y: 0,
            maxWidthDots: 480,
          );

          // Delay to allow printer to process Bitmap before next ticket
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

    // Close screen when work is complete
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
              // UI: Financial Summary Receipt (unchanged)
              _buildFinancialReceipt(financialResponse),
              const SizedBox(height: 24),
              // UI: All Tickets (modified layout inside)
              _buildTicketStubsWrap(widget.responses),
              const SizedBox(height: 24),
              // UI: Print Button
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
    // Check if payment is cash only
    bool isCashOnly = response.paymentDetails.length == 1 &&
        response.paymentDetails.first['method'] == 'CASH';

    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(response, isFinancialReceipt: true),

          // 🟢 Divider line
          const SizedBox(height: 12),
          const Divider(thickness: 1, color: Colors.black26),
          const SizedBox(height: 12),

          // Price section
          _buildInfoRow(
            'ລາຄາທັງໝົດ:',
            '${currencyFormat.format(response.amountDue)} ກີບ',
            isBold: true,
          ),
          const SizedBox(height: 4),
          _buildInfoRow(
            'ເງິນທີ່ໄດ້ຮັບ:',
            '${currencyFormat.format(response.amountPaid)} ກີບ',
          ),

          // 🟢 Payment method section (moved after amount received)
          if (response.paymentDetails.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'ຊຳລະຜ່ານ:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            ...response.paymentDetails.map((payment) {
              String methodName = payment['method'] ?? '';
              int amount = payment['amount'] ?? 0;

              // Convert to readable name
              String displayName = methodName;
              if (methodName == 'CASH') {
                displayName = 'ເງິນສົດ';
              } else if (methodName == 'BANKTF') {
                displayName = 'ເງິນໂອນ';
              }

              return Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '  • $displayName:',
                      style: const TextStyle(fontSize: 15, color: Colors.green),
                    ),
                    Text(
                      '${currencyFormat.format(amount)} ກີບ',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          // 🟢 Show change only when paying with cash only
          if (isCashOnly) ...[
            const SizedBox(height: 4),
            _buildInfoRow(
              'ເງິນທອນ:',
              '${currencyFormat.format(response.changeAmount)} ກີບ',
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 🟢 Ticket Stub (Added GlobalKey for Capture)
  // ===========================================================================
  Widget _buildTicketStub(ApiTicketResponse response, int index) {
    final DateTime now = DateTime.now();
    final String dateString = dateFormat.format(now);
    final String timeString = timeFormat.format(now);

    String ticketTypeString;
    String countString;
    if (response.adultCount >= 1) {
      ticketTypeString = 'ຜູ້ໃຫຍ່ ';
      countString = '${response.adultCount}';
    } else if (response.childCount >= 1) {
      ticketTypeString = 'ເດັກນ້ອຍ';
      countString = '${response.childCount}';
    } else {
      ticketTypeString = 'N/A';
      countString = '1';
    }

    return RepaintBoundary(
      // 🟢 1. Wrap with RepaintBoundary
      key: _ticketKeys[index], // 🟢 2. Bind GlobalKey
      child: Container(
        width: 480, // match printable width for 60mm label (~480 dots @203dpi)
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------
            // [LEFT COLUMN] : Date, Ticket Number, QR Code
            // -------------------------------------------------------
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Date & Time
                  Text(
                    'ວັນທີ: $dateString',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  Text(
                    'ເວລາ: $timeString',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),

                  const SizedBox(height: 12), // Spacing
                  // 2. Ticket Number
                  Text(
                    'ເລກທີ: ${response.purchaseId}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. QR Code (Centered in Left Column)
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

                  // 4. Ticket Type
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

            const SizedBox(width: 16), // Spacing between left-right columns
            // -------------------------------------------------------
            // [RIGHT COLUMN] : Laodoove, Header, Table
            // -------------------------------------------------------
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  // 1. Shop Name Laodoove (Right Aligned)
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

                  // 🔥 Small spacing to pull table closer to shop name
                  const SizedBox(height: 20),

                  // 2. Ride Type Header
                  const Text(
                    'ປະເພດເຄື່ອງຫຼິ້ນ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // 3. Table
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
  // 🟢 Helper Widgets for Ride Table
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

    // 1. Calculate half split (Dynamic Split)
    final int halfIndex = (rideNames.length / 2).ceil();

    final List<String> col1 = rideNames.sublist(0, halfIndex);
    final List<String> col2 = rideNames.sublist(halfIndex);

    // 2. Fill empty spaces in column 2 to match row count (for aesthetics)
    while (col2.length < col1.length) {
      col2.add('');
    }

    return Container(
      decoration: BoxDecoration(
        // Black table border
        border: Border.all(color: Colors.black, width: 1.0),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Column 1 (Left) ---
            Expanded(child: _buildRideColumn(col1)),

            // --- Center Divider ---
            const VerticalDivider(
              color: Colors.black,
              thickness: 1.0,
              width: 1,
            ),

            // --- Column 2 (Right) ---
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
        // If it's an empty space (added to fill)
        if (item.isEmpty) return const SizedBox(height: 22);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: const BoxDecoration(
              // (Optional)
              ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Align to top
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 3,
                ), // Move circle down slightly
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                    // 🟢 Add payment method
                    if (response.paymentMethods.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'ຊ່ອງທາງຊຳລະເງິນ: ${response.paymentMethods.map((method) {
                          if (method == 'CASH') return 'ເງິນສົດ';
                          if (method == 'BANKTF') return 'ເງິນໂອນ';
                          return method;
                        }).join(", ")}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  ],
                ),
              )
            else
              // Original header (for Financial Receipt if needed)
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
            color: Colors.black, // Changed to black for all
          ),
        ),
      ],
    );
  }

  Widget _buildQrCode(String qrData) {
    if (qrData.isEmpty) {
      return const Text('ບໍ່ສາມາດສ້າງ QR Code ໄດ້');
    }
    // If API sends SVG Base64, display it
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
