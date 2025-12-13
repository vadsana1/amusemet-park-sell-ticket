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
  // 🚀 เมธอดใหม่: พิมพ์รายงานสรุปกะ (Shift Report) - เพิ่มพารามิเตอร์
  // ---------------------------------------------------------------------------
  Future<void> printShiftReport({
    required String shiftId,
    required String cashierName,
    required String startDate,
    required String endDate,
    required String totalRevenue,
    required String totalTickets,
    // 🟢 [เพิ่ม] พารามิเตอร์ที่หายไปตามที่ shift_report_popup ส่งมา
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
      // 1. หัวข้อ (จัดกลาง)
      await iminPrinter.printText(
        'ລາຍງານສະຫຼຸບຮອບ',
        style: IminTextStyle(
          fontSize: 28,
          align: IminPrintAlign.center,
          fontStyle: IminFontStyle.bold,
        ),
      );
      await iminPrinter.printText('--------------------------------');

      // 2. ข้อมูลผู้ขายและกะ (จัดชิดซ้าย)
      await iminPrinter.printText(
        'ຜູ້ຂາຍ: $cashierName',
        style: IminTextStyle(fontSize: 12, align: IminPrintAlign.left),
      );
      await iminPrinter.printText(
        'ເລກທີຮອບ: $shiftId',
        style: IminTextStyle(fontSize: 12, align: IminPrintAlign.left),
      );
      await iminPrinter.printText('--------------------------------');

      // 3. ข้อมูลช่วงเวลา
      await iminPrinter.printText(
        '--- ໄລຍະເວລາ ---',
        style: IminTextStyle(fontSize: 14, align: IminPrintAlign.center),
      );
      await iminPrinter.printText(
        'ເລີ່ມ: $startDate',
        style: IminTextStyle(fontSize: 14, align: IminPrintAlign.left),
      );
      await iminPrinter.printText(
        'ສິ້ນສຸດ: $endDate',
        style: IminTextStyle(fontSize: 14, align: IminPrintAlign.left),
      );
      await iminPrinter.printText('--------------------------------');

      // 4. สรุปยอดขาย (ใช้ _printRow เพื่อจัดชิดซ้าย-ขวา)

      await iminPrinter.printText(
        '--- ຍອດຂາຍ (Sales) ---',
        style: IminTextStyle(fontSize: 14, align: IminPrintAlign.center),
      );
      // ยอดขายรวม
      await _printRow('ຍອດຂາຍທັງໝົດ:', '$totalRevenue ກີບ', isBold: true);
      // ยอดขายแยกประเภท
      await _printRow(' - ຜູ້ໃຫຍ່:', '$adultSales ກີບ');
      await _printRow(' - ເດັກນ້ອຍ:', '$childSales ກີບ');

      await iminPrinter.printText('--------------------------------');

      // 5. สรุปจำนวนผู้เข้าชม
      await iminPrinter.printText(
        '--- ຈຳນວນປີ້ (Tickets) ---',
        style: IminTextStyle(fontSize: 14, align: IminPrintAlign.center),
      );
      await _printRow('ລວມຈໍານວນປີ້ຂາຍ:', '$totalTickets ໃບ', isBold: true);
      await _printRow(' - ຜູ້ໃຫຍ່:', '$adultVisitors ຄົນ');
      await _printRow(' - ເດັກນ້ອຍ:', '$childVisitors ຄົນ');
      await _printRow('ລວມຄົນເຂົ້າຊົມ:',
          '$totalVisitors ຄົນ'); // ซ้ำกับด้านบน แต่เพิ่มความชัดเจน

      await iminPrinter.printText('--------------------------------');

      // 6. ช่องทางการชำระเงิน
      await iminPrinter.printText(
        '--- ການຊໍາລະ ---',
        style: IminTextStyle(fontSize: 12, align: IminPrintAlign.center),
      );
      for (var p in payments) {
        // p['method'] คือชื่อเต็ม, p['total'] คือยอด
        await _printRow('${p['method']}:', '${p['total']} ກີບ', isBold: true);
      }

      await iminPrinter.printText('--------------------------------');

      // 7. สรุปเครื่องเล่น
      await iminPrinter.printText(
        '--- ການຫຼິ້ນ (Rides) ---',
        style: IminTextStyle(fontSize: 12, align: IminPrintAlign.center),
      );
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

// ... [printFinancialReceipt, printTicketStub, _printRow, _getVisibleLength เหมือนเดิม] ...

// ---------------------------------------------------------------------------
// เมธอดอื่นๆ ที่มีอยู่แล้ว
// ---------------------------------------------------------------------------

  /// พิมพ์ใบสรุปการเงิน
  Future<void> printFinancialReceipt(
    ApiTicketResponse response,
    String sellerName,
  ) async {
// ... (โค้ด printFinancialReceipt เหมือนเดิม) ...
    final DateTime now = DateTime.now();
    final String dateString = dateFormat.format(now);
    final String timeString = timeFormat.format(now);

    // ==========================================
    // ส่วน Header: ชิดซ้าย วันที่/เวลา อยู่คนละบรรทัด
    // ==========================================

    // 1. เลขบิล (บรรทัดแรก)
    await iminPrinter.printText(
      'ເລກທີໃບບິນ: ${response.purchaseId}',
      style: IminTextStyle(
        fontSize: 32,
        align: IminPrintAlign.left,
        fontStyle: IminFontStyle.bold,
      ),
    );

    // 2. วันที่ และ เวลา (อยู่บรรทัดเดียวกัน เว้นวรรค)
    await iminPrinter.printText(
      'ວັນທີ: $dateString ເວລາ: $timeString',
      style: IminTextStyle(
        fontSize: 26,
        align: IminPrintAlign.left,
      ),
    );

    // 3. ผู้ขาย (บรรทัดถัดมา)
    await iminPrinter.printText(
      'ຜູ້ຂາຍ: $sellerName',
      style: IminTextStyle(
        fontSize: 26,
        align: IminPrintAlign.left,
      ),
    );

    await iminPrinter.printText('------------------------------------------');

    // --- รายละเอียดเงิน ---
    // ใช้ _printRow ตัวใหม่ที่คำนวณแม่นยำขึ้น
    await _printRow(
      'ລາຄາທັງໝົດ:',
      '${currencyFormat.format(response.amountDue)} ກີບ',
      isBold: true, // ตัวหนา -> จะใช้สูตรคำนวณสำหรับฟอนต์ใหญ่
    );
    await _printRow(
      'ເງິນທີ່ໄດ້ຮັບ:',
      '${currencyFormat.format(response.amountPaid)} ກີບ',
    ); // ปกติ -> ใช้สูตรฟอนต์ปกติ
    await _printRow(
      'ເງິນທອນ:',
      '${currencyFormat.format(response.changeAmount)} ກີບ',
    ); // ปกติ -> ใช้สูตรฟอนต์ปกติ

    // --- Footer & Cut ---
    await iminPrinter.printAndFeedPaper(120);
    await iminPrinter.partialCut();
  }

  /// พิมพ์ตั๋ว (Ticket Stub)
  Future<void> printTicketStub(
    ApiTicketResponse response,
    String sellerName,
  ) async {
// ... (โค้ด printTicketStub เหมือนเดิม) ...
    final DateTime now = DateTime.now();
    final String dateString = dateFormat.format(now);
    final String timeString = timeFormat.format(now);
    String ticketTypeString;

    if (response.adultCount == 1) {
      ticketTypeString = 'ຜູ້ໃຫຍ່ (Adult)';
    } else if (response.childCount == 1) {
      ticketTypeString = 'ເດັກນ້ອຍ (Child)';
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

    // --- Header Ticket ---

    // 1. ID
    await iminPrinter.printText(
      'ID ປີ້: ${response.purchaseId}',
      style: IminTextStyle(
        fontSize: 32,
        align: IminPrintAlign.left,
        fontStyle: IminFontStyle.bold,
      ),
    );

    // 2. วันที่ และ เวลา
    await iminPrinter.printText(
      'ວັນທີ: $dateString ເວລາ: $timeString',
      style: IminTextStyle(fontSize: 26, align: IminPrintAlign.left),
    );

    // 3. ผู้ขาย
    await iminPrinter.printText(
      'ຜູ້ຂາຍ: $sellerName',
      style: IminTextStyle(fontSize: 26, align: IminPrintAlign.left),
    );

    // 4. ประเภทตั๋ว
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

  /// (Helper) ฟังก์ชันพิมพ์ 2 ฝั่ง แบบปรับขนาดอัตโนมัติ (Dynamic Align)
  Future<void> _printRow(
    String label,
    String value, {
    bool isBold = false,
  }) async {
    // -------------------------------------------------------------------
    // [แก้ไขจุดสำคัญ] สูตรคำนวณพื้นที่
    // - ถ้าตัวหนา (Size 24) ตัวหนังสือจะอ้วน กินที่เยอะ -> ให้ใช้แค่ 42 ช่อง
    // - ถ้าตัวปกติ (Size 22) ตัวหนังสือจะผอมกว่า -> ให้ใช้ 52 ช่อง
    // -------------------------------------------------------------------
    int maxLineChars = isBold ? 42 : 52;

    int labelWidth = _getVisibleLength(label);
    int valueWidth = _getVisibleLength(value);

    int spaceCount = maxLineChars - (labelWidth + valueWidth);

    if (spaceCount < 1) spaceCount = 1;

    String spaces = ' ' * spaceCount;
    String finalLine = '$label$spaces$value';

    await iminPrinter.printText(
      finalLine,
      style: IminTextStyle(
        fontSize: isBold ? 24 : 22,
        align: IminPrintAlign.left,
        fontStyle: isBold ? IminFontStyle.bold : IminFontStyle.normal,
      ),
    );
  }

  /// ฟังก์ชันช่วยนับความกว้าง (ตัดสระลาวออก)
  int _getVisibleLength(String text) {
    if (text.isEmpty) return 0;
    final laoNonSpacingRegex = RegExp(r'[\u0EB1\u0EB4-\u0EBC\u0EC8-\u0ECD]');
    String cleanText = text.replaceAll(laoNonSpacingRegex, '');
    return cleanText.length;
  }
}
