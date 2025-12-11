// services/receipt_printer_service.dart
import 'dart:developer';
import 'package:intl/intl.dart';
// The package's main entry typically exports the types we need,
// so prefer the consolidated import to avoid analyzer/export issues.
import 'package:imin_printer/imin_printer.dart';
import 'package:imin_printer/enums.dart';
import 'package:imin_printer/imin_style.dart';
import 'package:imin_printer/column_maker.dart';
// ต้อง import Model ของคุณด้วย
import '../models/api_ticket_response.dart';

class ReceiptPrinterService {
  final iminPrinter = IminPrinter();

  // Formatters
  final dateFormat = DateFormat('dd/MM/yyyy');
  final timeFormat = DateFormat('HH:mm');
  final currencyFormat = NumberFormat("#,##0", "en_US");

  /// เตรียมความพร้อมเครื่องพิมพ์
  Future<void> initPrinter() async {
    try {
      // 3. [แก้ไข] กลับไปใช้ init แบบง่าย
      await iminPrinter.initPrinter();
      log("Printer Initialized (Service)");
    } catch (e) {
      log("Printer Init Error: $e");
    }
  }

  /// พิมพ์ใบสรุปการเงิน
  Future<void> printFinancialReceipt(
    ApiTicketResponse response,
    String sellerName,
  ) async {
    final DateTime now = DateTime.now();
    final String dateString = dateFormat.format(now);
    final String timeString = timeFormat.format(now);

    // --- Header ---
    await iminPrinter.printText(
      'ເລກທີໃບບິນ: ${response.purchaseId}',
      style: IminTextStyle(
        fontSize: 24,
        align: IminPrintAlign.left,
        fontStyle: IminFontStyle.bold,
      ),
    );
    await iminPrinter.printText(
      'ຜູ້ຂາຍ: $sellerName',
      style: IminTextStyle(fontSize: 19, align: IminPrintAlign.left),
    );
    await iminPrinter.printText(
      'ວັນທີ: $dateString  ເວລາ: $timeString',
      style: IminTextStyle(fontSize: 19, align: IminPrintAlign.left),
    );
    await iminPrinter.printText('--------------------------------');
    await _printRow(
      'ລາຄາທັງໝົດ:',
      '${currencyFormat.format(response.amountDue)} ກີບ',
      isBold: true,
    );
    await _printRow(
      'ເງິນທີ່ໄດ້ຮັບ:',
      '${currencyFormat.format(response.amountPaid)} ກີບ',
    );
    await _printRow(
      'ເງິນທອນ:',
      '${currencyFormat.format(response.changeAmount)} ກີບ',
    );
    await iminPrinter.printAndFeedPaper(10);
    await iminPrinter.partialCut();
  }

  /// พิมพ์ตั๋ว (Ticket Stub) พร้อม QR Code
  Future<void> printTicketStub(
    ApiTicketResponse response,
    String sellerName,
  ) async {
    // ... (โค้ด Header ทั้งหมดถูกต้องแล้ว ไม่ต้องแก้ไข) ...

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
        fontSize: 24,
        align: IminPrintAlign.center,
        fontStyle: IminFontStyle.bold,
      ),
    );
    await iminPrinter.printAndFeedPaper(10);
    await iminPrinter.printText(
      'ID ປີ້: ${response.purchaseId}',
      style: IminTextStyle(
        fontSize: 24,
        align: IminPrintAlign.left,
        fontStyle: IminFontStyle.bold,
      ),
    );
    await iminPrinter.printText(
      'ຜູ້ຂາຍ: $sellerName',
      style: IminTextStyle(fontSize: 19, align: IminPrintAlign.left),
    );
    await iminPrinter.printText(
      'ວັນທີ: $dateString  ເວລາ: $timeString',
      style: IminTextStyle(fontSize: 19, align: IminPrintAlign.left),
    );
    await iminPrinter.printText(
      'ປະເພດປີ້: $ticketTypeString',
      style: IminTextStyle(fontSize: 19, align: IminPrintAlign.left),
    );

    await iminPrinter.printText('--------------------------------');

    //
    // --- 4. [สำคัญ] การพิมพ์ QR Code (แก้ไข) ---
    //
    // เราจะเรียกใช้ `printQrCode` โดยส่งไปแค่ String (ข้อมูล)
    // เพราะเวอร์ชันของคุณไม่รองรับพารามิเตอร์อื่น
    //
    await iminPrinter.printQrCode(response.purchaseId.toString());
    //
    // --- [สิ้นสุดการพิมพ์ QR Code] ---
    //

    await iminPrinter.printText('--------------------------------');

    // --- Ride List ---
    await iminPrinter.printText(
      'ປະເພດເຄື່ອງຫຼິ້ນ',
      style: IminTextStyle(
        fontSize: 24,
        align: IminPrintAlign.left,
        fontStyle: IminFontStyle.bold,
      ),
    );
    for (String rideName in response.rideNames) {
      await iminPrinter.printText(
        '• $rideName',
        style: IminTextStyle(fontSize: 19, align: IminPrintAlign.left),
      );
    }

    // --- Footer ---
    await iminPrinter.printAndFeedPaper(10);
    await iminPrinter.partialCut();
  }

  /// (Helper) ฟังก์ชันพิมพ์แบบ 2 คอลัมน์
  Future<void> _printRow(
    String label,
    String value, {
    bool isBold = false,
  }) async {
    //
    // 💡 [หมายเหตุ]
    // Error `IminColumnsText` (Lines 202, 210) เป็น Error "ผี"
    // ที่เกิดจาก Error การ import ด้านบน
    // เมื่อคุณแก้โค้ด QR Code แล้ว Error นี้ควรจะหายไป
    //
    await iminPrinter.printColumnsText(
      cols: [
        ColumnMaker(
          text: label,
          width: 2,
          fontSize: isBold ? 22 : 19,
          align: IminPrintAlign.left,
        ),
        ColumnMaker(
          text: value,
          width: 2,
          fontSize: isBold ? 22 : 19,
          align: IminPrintAlign.right,
        ),
      ],
    );
  }
} // End of class
