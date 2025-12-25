// [ FILE: lib/services/receipt_printer_service.dart ]

import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:imin_printer/imin_printer.dart';
import 'package:imin_printer/enums.dart';
import 'package:imin_printer/imin_style.dart';
import '../models/api_ticket_response.dart';

class ReceiptPrinterService {
  final iminPrinter = IminPrinter();

  // Formatters
  final dateFormat = DateFormat('dd/MM/yyyy');
  final timeFormat = DateFormat('HH:mm');
  final currencyFormat = NumberFormat("#,##0", "en_US");

  Future<void> initPrinter() async {
    try {
      await iminPrinter.initPrinter();
      log("Printer Initialized (Service)");
    } catch (e) {
      log("Printer Init Error: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 🚀 New Method: Print Shift Summary Report - Added Parameters
  // ---------------------------------------------------------------------------
  Future<void> printShiftReport({
    required String shiftId,
    required String cashierName,
    required String startDate,
    required String endDate,
    required String totalRevenue,
    required String totalTickets,
    // 🟢 [Added] Missing parameters as sent by shift_report_popup
    required String adultSales,
    required String childSales,
    required String totalVisitors,
    required String adultVisitors,
    required String childVisitors,
    required List<Map<String, String>> payments,
    required String totalPlays,
    required String adultsPlayed,
    required String childrenPlayed,
  }) async {
    try {
      // 1. Report Title
      await iminPrinter.printText(
        'ລາຍງານສະຫຼຸບຮອບ',
        style: IminTextStyle(
          fontSize: 32,
          align: IminPrintAlign.center,
          fontStyle: IminFontStyle.bold,
        ),
      );
      await iminPrinter.printText('--------------------------------');

      // 2. Seller and shift info (left aligned, bigger font)
      await iminPrinter.printText(
        'ຜູ້ຂາຍ: $cashierName',
        style: IminTextStyle(fontSize: 20, align: IminPrintAlign.left),
      );
      await iminPrinter.printText(
        'ເລກທີຮອບ: $shiftId',
        style: IminTextStyle(fontSize: 20, align: IminPrintAlign.left),
      );
      await iminPrinter.printText('--------------------------------');

      // 3. Time period info (bigger font)
      await iminPrinter.printText(
        'ເລີ່ມ: $startDate',
        style: IminTextStyle(fontSize: 20, align: IminPrintAlign.left),
      );
      await iminPrinter.printText(
        'ສິ້ນສຸດ: $endDate',
        style: IminTextStyle(fontSize: 20, align: IminPrintAlign.left),
      );
      await iminPrinter.printText('--------------------------------');

      // 4. Sales summary (use _printRow for left-right alignment)

      // Sales summary (no section header)
      // Total sales
      await _printRow('ຍອດຂາຍທັງຫມົດ:', '$totalRevenue ກີບ', isBold: true);
      // Sales by category
      await _printRow(' - ຜູ້ໃຫຍ່:', '$adultSales ກີບ');
      await _printRow(' - ເດັກນ້ອຍ:', '$childSales ກີບ');

      await iminPrinter.printText('--------------------------------');
      // 5. Visitor count summary (no section header)
      await _printRow('ລວມຈໍານວນປີ້ຂາຍ:', '$totalTickets ໃບ', isBold: true);
      await _printRow(' - ຜູ້ໃຫຍ່:', '$adultVisitors ໃບ');
      await _printRow(
          ' - ເດັກນ້ອຍ:', '$childVisitors ໃບ'); // เปลี่ยนเป็นจำนวนปี้ทั้งหมด

      await iminPrinter.printText('--------------------------------');
      // 6. Payment methods (no section header)
      for (var p in payments) {
        // p['method'] is full name, p['total'] is amount
        await _printRow('${p['method']}:', '${p['total']} ກີບ', isBold: true);
      }

      await iminPrinter.printText('--------------------------------');
      // 7. Rides summary (no section header)
      await _printRow('ລວມການຫຼິ້ນ:', '$totalPlays ຄັ້ງ');
      await _printRow(' - ຜູ້ໃຫຍ່:', '$adultsPlayed ຄັ້ງ');
      await _printRow(' - ເດັກນ້ອຍ:', '$childrenPlayed ຄັ້ງ');

      await iminPrinter.printText('--------------------------------');

      // --- Footer & Cut ---
      await iminPrinter.printAndFeedPaper(120);
      await iminPrinter.partialCut();

      log("✅ Shift Report Printed via iMin.");
    } catch (e) {
      log("❌ Error printing Shift Report: $e");
      rethrow;
    }
  }

// ... [printFinancialReceipt, printTicketStub, _printRow, _getVisibleLength same as before] ...

// ---------------------------------------------------------------------------
// Other Existing Methods
// ---------------------------------------------------------------------------

  /// Print Financial Summary Receipt
  Future<void> printFinancialReceipt(
    ApiTicketResponse response,
    String sellerName,
  ) async {
// ... (code for printFinancialReceipt same as before) ...
    final DateTime now = DateTime.now();
    final String dateString = dateFormat.format(now);
    final String timeString = timeFormat.format(now);

    // ==========================================
    // Header Section: Left aligned, Date/Time on separate lines
    // ==========================================

    // 1. Bill number (first line)
    await iminPrinter.printText(
      'ເລກທີໃບບິນ: ${response.purchaseId}',
      style: IminTextStyle(
        fontSize: 32,
        align: IminPrintAlign.left,
        fontStyle: IminFontStyle.bold,
      ),
    );

    // 2. Date and Time (on same line with space)
    await iminPrinter.printText(
      'ວັນທີ: $dateString ເວລາ: $timeString',
      style: IminTextStyle(
        fontSize: 26,
        align: IminPrintAlign.left,
      ),
    );

    // 3. Seller (next line)
    await iminPrinter.printText(
      'ຜູ້ຂາຍ: $sellerName',
      style: IminTextStyle(
        fontSize: 26,
        align: IminPrintAlign.left,
      ),
    );

    // 4. Payment method
    if (response.paymentMethods.isNotEmpty) {
      // Convert method codes to Lao names
      final displayMethods = response.paymentMethods.map((method) {
        if (method == 'CASH') return 'ເງິນສົດ';
        if (method == 'BANKTF') return 'ເງິນໂອນ';
        if (method == 'QR') return 'QR';
        return method;
      }).join(", ");

      await iminPrinter.printText(
        'ຊ່ອງທາງຊຳລະເງິນ: $displayMethods',
        style: IminTextStyle(
          fontSize: 26,
          align: IminPrintAlign.left,
        ),
      );
    } else if (response.paymentDetails.isNotEmpty) {
      // If paymentMethods is empty, extract from paymentDetails and convert names
      List<String> methods = response.paymentDetails
          .map((p) {
            String methodCode = p['method']?.toString() ?? '';
            if (methodCode == 'CASH') return 'ເງິນສົດ';
            if (methodCode == 'BANKTF') return 'ເງິນໂອນ';
            if (methodCode == 'QR') return 'QR';
            return methodCode;
          })
          .where((m) => m.isNotEmpty)
          .toList();
      if (methods.isNotEmpty) {
        await iminPrinter.printText(
          'ຊ່ອງທາງຊຳລະເງິນ: ${methods.join(", ")}',
          style: IminTextStyle(
            fontSize: 26,
            align: IminPrintAlign.left,
          ),
        );
      }
    }

    await iminPrinter.printText('------------------------------------------');

    // --- Payment details ---
    await _printRow(
      'ລາຄາທັງຫມົດ:',
      '${currencyFormat.format(response.amountDue)} ກີບ',
      isBold: true,
    );

    await _printRow(
      'ເງິນທີ່ໄດ້ຮັບ:',
      '${currencyFormat.format(response.amountPaid)} ກີບ',
    );

    // 🟢 Check if payment is cash only
    bool isCashOnly = response.paymentDetails.length == 1 &&
        response.paymentDetails.first['method'] == 'CASH';

    // Show detailed payment breakdown (only for mixed payment)
    if (response.paymentDetails.length > 1) {
      for (var payment in response.paymentDetails) {
        String methodName = payment['method'] ?? '';
        int amount = payment['amount'] ?? 0;

        // Convert method name to Lao
        String displayName = '';
        if (methodName == 'CASH') {
          displayName = 'ເງິນສົດ';
        } else if (methodName == 'BANKTF') {
          displayName = 'ເງິນໂອນ';
        } else if (methodName == 'QR') {
          displayName = 'QR';
        } else {
          displayName = methodName;
        }

        await _printRow(
          '  • $displayName:',
          '${currencyFormat.format(amount)} ກີບ',
        );
      }
    }

    // 🟢 Show change only for cash-only payment
    if (isCashOnly) {
      await _printRow(
        'ເງິນທອນ:',
        '${currencyFormat.format(response.changeAmount)} ກີບ',
      );
    }

    // --- Footer & Cut ---
    await iminPrinter.printAndFeedPaper(120);
    await iminPrinter.partialCut();
  }

  /// Print Ticket (Ticket Stub)
  Future<void> printTicketStub(
    ApiTicketResponse response,
    String sellerName,
  ) async {
// ... (code for printTicketStub same as before) ...
    final DateTime now = DateTime.now();
    final String dateString = dateFormat.format(now);
    final String timeString = timeFormat.format(now);
    String ticketTypeString;

    if (response.adultCount == 1) {
      ticketTypeString = 'ຜູ້ໃຫຍ່';
    } else if (response.childCount == 1) {
      ticketTypeString = 'ເດັກນ້ອຍ';
    } else {
      ticketTypeString = 'N/A';
    }

    await iminPrinter.printText(
      'ປີ້ສຳລັບເຂົ້າເຄື່ອງຫຼິ້ນ',
      style: IminTextStyle(
        fontSize: 35,
        align: IminPrintAlign.center,
        fontStyle: IminFontStyle.bold,
      ),
    );
    await iminPrinter.printAndFeedPaper(20);

    // --- Ticket Header ---

    // 1. ID
    await iminPrinter.printText(
      'ID ປີ້: ${response.purchaseId}',
      style: IminTextStyle(
        fontSize: 32,
        align: IminPrintAlign.left,
        fontStyle: IminFontStyle.bold,
      ),
    );

    // 2. Date and Time
    await iminPrinter.printText(
      'ວັນທີ: $dateString ເວລາ: $timeString',
      style: IminTextStyle(fontSize: 26, align: IminPrintAlign.left),
    );

    // 3. Seller
    await iminPrinter.printText(
      'ຜູ້ຂາຍ: $sellerName',
      style: IminTextStyle(fontSize: 26, align: IminPrintAlign.left),
    );

    // 4. Ticket type
    await iminPrinter.printText(
      'ປະເພດປີ້: $ticketTypeString',
      style: IminTextStyle(fontSize: 26, align: IminPrintAlign.left),
    );

    await iminPrinter.printText('------------------------------------------');
    await iminPrinter.printQrCode(response.purchaseId.toString());
    await iminPrinter.printText('------------------------------------------');

    // --- Ride List ---
    await iminPrinter.printText(
      'ປະເພດເຄື່ອງຫຼິ້ນ',
      style: IminTextStyle(
        fontSize: 30,
        align: IminPrintAlign.left,
        fontStyle: IminFontStyle.bold,
      ),
    );
    for (String rideName in response.rideNames) {
      await iminPrinter.printText(
        '• $rideName',
        style: IminTextStyle(fontSize: 26, align: IminPrintAlign.left),
      );
    }

    // --- Footer & Cut ---
    await iminPrinter.printAndFeedPaper(120);
    await iminPrinter.partialCut();
  }

  /// (Helper) Print 2-column aligned text (for 80mm paper)
  Future<void> _printRow(
    String label,
    String value, {
    bool isBold = false,
  }) async {
    // Define fixed label width of 20 characters
    const int labelWidth = 20;
    const int totalWidth = 54;

    // Calculate actual length (excluding Lao vowels)
    int labelLen = _getVisibleLength(label);
    int valueLen = _getVisibleLength(value);

    // Pad label with spaces to reach labelWidth
    int labelSpaces = labelWidth - labelLen;
    if (labelSpaces < 0) labelSpaces = 0;

    String paddedLabel = label + (' ' * labelSpaces);

    // Calculate space between label and value
    int remainingWidth = totalWidth - labelWidth - valueLen;
    if (remainingWidth < 1) remainingWidth = 1;

    String spaces = ' ' * remainingWidth;
    String line = '$paddedLabel$spaces$value';

    await iminPrinter.printText(
      line,
      style: IminTextStyle(
        fontSize: isBold ? 24 : 22,
        align: IminPrintAlign.left,
        fontStyle: isBold ? IminFontStyle.bold : IminFontStyle.normal,
      ),
    );
  }

  int _getVisibleLength(String text) {
    if (text.isEmpty) return 0;

    final laoNonSpacingRegex = RegExp(r'[\u0EB1\u0EB4-\u0EBC\u0EC8-\u0ECD]');
    String cleanText = text.replaceAll(laoNonSpacingRegex, '');
    return cleanText.length;
  }
}
