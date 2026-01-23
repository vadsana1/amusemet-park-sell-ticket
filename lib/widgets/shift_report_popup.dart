// [ FILE: lib/widgets/shift_report_popup.dart ]

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// ⚠️ ต้อง Import ReceiptPrinterService สำหรับ iMin
import '../services/receipt_printer_service.dart';

// เนื่องจาก ShiftSummaryScreen ส่ง Map มาที่นี่ เราจึงใช้ Map
// และลบ Class ShiftReport Example ที่ซ้ำซ้อนออกไป
class ShiftReportPopup extends StatefulWidget {
  final Map<String, dynamic>
      reportData; // 🟢 แก้ไข: รับเป็น Map<String, dynamic>

  const ShiftReportPopup({super.key, required this.reportData});

  @override
  State<ShiftReportPopup> createState() => _ShiftReportPopupState();
}

class _ShiftReportPopupState extends State<ShiftReportPopup> {
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");
  final ReceiptPrinterService _iminService = ReceiptPrinterService();
  bool _hasPrinted = false; // ตัวแปรเช็คว่าได้กดปริ้นแล้วหรือยัง

  // --- Helpers แปลงข้อมูลปลอดภัย ---
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    // แปลง String ที่มีลูกน้ำ (เช่น "1,940,000.00") ให้เป็น double
    return double.tryParse(value.toString().replaceAll(',', '')) ?? 0.0;
  }

  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    // แปลงเป็น int และจัดการกรณีทศนิยมถ้ามี
    return int.tryParse(
            value.toString().replaceAll(',', '').split('.').first) ??
        0;
  }
  // ----------------

  // --- ฟังก์ชันพิมพ์ผ่าน iMin Printer ---
  Future<void> _printReport(BuildContext context) async {
    try {
      // 1. ดึงข้อมูลจาก Map
      final Map<String, dynamic> user = widget.reportData['user'] ?? {};
      final Map<String, dynamic> sales = widget.reportData['sales'] ?? {};
      final Map<String, dynamic> visitors = widget.reportData['visitors'] ?? {};
      final List<dynamic> payments = widget.reportData['payments'] ?? [];
      final Map<String, dynamic> rides = widget.reportData['rides'] ?? {};
      final String closedAt = widget.reportData['closed_at'] ?? '-';

      int totalVisitors = _safeParseInt(visitors['total_adults']) +
          _safeParseInt(visitors['total_children']);

      // 2. เตรียมข้อมูลสำหรับพิมพ์
      final String staffName = user['staff_name']?.toString() ?? '-';
      final String totalSales =
          _currencyFormat.format(_safeParseDouble(sales['total_sales']));
      final String totalTickets = '${sales['total_tickets'] ?? 0}';
      final String adultSales =
          _currencyFormat.format(_safeParseDouble(sales['adult_sales']));
      final String childSales =
          _currencyFormat.format(_safeParseDouble(sales['child_sales']));

      // 3. สร้างรายการ payments เป็น List<Map<String, String>>
      final List<Map<String, String>> paymentList = payments.map((p) {
        final pMap = p as Map<String, dynamic>;
        return {
          'method': pMap['method']?.toString() ?? 'Unknown',
          'total': _currencyFormat.format(_safeParseDouble(pMap['total'])),
          'code': pMap['code']?.toString() ?? '',
        };
      }).toList();

      // 4. เรียกใช้ iMin printer service
      await _iminService.printShiftReport(
        shiftId: user['staff_id']?.toString() ?? '-',
        cashierName: staffName,
        startDate: closedAt,
        endDate: closedAt,
        totalRevenue: totalSales,
        totalTickets: totalTickets,
        adultSales: adultSales,
        childSales: childSales,
        totalVisitors:
            totalTickets, // Keep this if needed or repurpose as total tickets
        adultVisitors: '${sales['total_adult_tickets'] ?? 0}',
        childVisitors: '${sales['total_child_tickets'] ?? 0}',
        payments: paymentList,
        totalPlays: '${rides['total_plays'] ?? 0}',
        adultsPlayed: '${rides['adults_played'] ?? 0}',
        childrenPlayed: '${rides['children_played'] ?? 0}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ສົ່ງຄຳສັ່ງພິມໄປຫາເຄື່ອງ iMin ແລ້ວ'),
            backgroundColor: Colors.green,
          ),
        );
        // 🟢 เพิ่ม: ตั้งค่าว่าได้ปริ้นแล้ว
        setState(() {
          _hasPrinted = true;
        });
      }
    } catch (e) {
      log("Error printing Shift Report: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ເກີດຂໍ້ຜິດພາດ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showConfirmDialog(BuildContext context) async {
    final NavigatorState navigator = Navigator.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ຢືນຢັນການປິດຮອບ'),
          content: const Text('ທ່ານແນ່ໃຈບໍ່ວ່າຕ້ອງການຢືນຢັນການປິດຮອບນີ້?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'ຍົກເລີກ',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
              child: const Text('ຢືນຢັນ'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. ดึงข้อมูลมาแสดงบนหน้าจอ
    final Map<String, dynamic> user = widget.reportData['user'] ?? {};
    final Map<String, dynamic> sales = widget.reportData['sales'] ?? {};
    final List<dynamic> payments = widget.reportData['payments'] ?? [];
    final Map<String, dynamic> rides = widget.reportData['rides'] ?? {};
    final String closedAt = widget.reportData['closed_at'] ?? '-';

    return WillPopScope(
      onWillPop: () async {
        // ถ้าปริ้นแล้ว ห้ามย้อนกลับ
        return !_hasPrinted;
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment_turned_in, color: Color(0xFF1A9A8B)),
                SizedBox(width: 10),
                Text('ສະຫຼຸບຍອດ (Report)', style: TextStyle(fontSize: 18)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.print, color: Colors.blue),
              tooltip: 'Print Report',
              onPressed: () => _printReport(context),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader('👤 ຂໍ້ມູນຜູ້ປິດຮອບ'),
                _buildInfoRow(
                    'ພະນັກງານ:', user['staff_name']?.toString() ?? '-'),
                _buildInfoRow('ເວລາປິດຮອບ:', closedAt),
                const Divider(height: 24),

                _buildSectionHeader('💰 ຍອດຂາຍ'),
                _buildInfoRow(
                  'ຍອດຂາຍລວມ:',
                  '${_currencyFormat.format(_safeParseDouble(sales['total_sales']))} ກີບ',
                  isTotal: true,
                ),
                _buildInfoRow(
                  ' - ຍອດຜູ້ໃຫຍ່:',
                  '${_currencyFormat.format(_safeParseDouble(sales['adult_sales']))} ກີບ',
                ),
                _buildInfoRow(
                  ' - ຍອດເດັກນ້ອຍ:',
                  '${_currencyFormat.format(_safeParseDouble(sales['child_sales']))} ກີບ',
                ),
                const Divider(height: 24),

                _buildSectionHeader('👥 ຈຳນວນປີ້ທີ່ຂາຍ'),
                _buildInfoRow(
                    'ລວມທັງໝົດ:', '${sales['total_tickets'] ?? 0} ປີ້',
                    isTotal: true),
                _buildInfoRow(
                  ' - ຜູ້ໃຫຍ່:',
                  '${sales['total_adult_tickets'] ?? 0} ປີ້',
                ),
                _buildInfoRow(
                  ' - ເດັກນ້ອຍ:',
                  '${sales['total_child_tickets'] ?? 0} ປີ້',
                ),
                const Divider(height: 24),

                // ---------------------------------------------
                if (payments.isNotEmpty) ...[
                  _buildSectionHeader('💳 ປະເພດການຈ່າຍເງິນ'),
                  ...payments.map((payment) {
                    final pMap = payment as Map<String, dynamic>;
                    return _buildInfoRow(
                      ' - ${pMap['method'] ?? 'Unknown'}:',
                      '${_currencyFormat.format(_safeParseDouble(pMap['total']))} ກີບ',
                    );
                  }),
                  const Divider(height: 24),
                ],

                _buildSectionHeader('🎠 ຂໍ້ມູນເຄື່ອງຫຼິ້ນ'),
                _buildInfoRow(
                  'ຈຳນວນຫຼິ້ນທັງໝົດ:',
                  '${rides['total_plays'] ?? 0} ຄັ້ງ',
                ),
                _buildInfoRow(
                  ' - ຜູ້ໃຫຍ່ຫຼິ້ນ:',
                  '${rides['adults_played'] ?? 0} ຄັ້ງ',
                ),
                _buildInfoRow(
                  ' - ເດັກນ້ອຍຫຼິ້ນ:',
                  '${rides['children_played'] ?? 0} ຄັ້ງ',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _hasPrinted ? null : () => _printReport(context),
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Print'),
            style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed:
                _hasPrinted ? null : () => Navigator.of(context).pop(false),
            child: const Text('ກັບຄືນ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _hasPrinted
                ? () => _showConfirmDialog(context)
                : () {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange),
                              SizedBox(width: 10),
                              Text('ແຈ້ງເຕືອນ'),
                            ],
                          ),
                          content:
                              const Text('ກະລຸນາກົດ Print ກ່ອນຢືນຢັນປິດກະ'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('ປິດ'),
                            ),
                          ],
                        );
                      },
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _hasPrinted ? const Color(0xFF1A9A8B) : Colors.grey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('ຢືນຢັນປິດກະ'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A9A8B),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.red[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
