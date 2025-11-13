import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class ShiftReportPopup extends StatelessWidget {
  final Map<String, dynamic> reportData;
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");

  ShiftReportPopup({super.key, required this.reportData});

  // Helper 
  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString().replaceAll(',', '')) ?? 0.0;
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
            // cancel button
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false),
              child: const Text('ຍົກເລີກ'),
            ),
            // confirm button
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true), 
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red[700],
              ),
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
    // ດຶງຂໍ້ມູນຈາກ Map
    final Map<String, dynamic> user =
        reportData['user'] as Map<String, dynamic>;
    final Map<String, dynamic> sales =
        reportData['sales'] as Map<String, dynamic>;
    final List<dynamic> payments = reportData['payments'] as List<dynamic>;
    final Map<String, dynamic> rides =
        reportData['rides'] as Map<String, dynamic>;
    final String closedAt = reportData['closed_at'] as String;

    return AlertDialog(
      title: const Text('📋 ສະຫຼຸບຍອດ (Shift Report)'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400, 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSectionHeader('👤 ຂໍ້ມູນຜູ້ປິດຮອບ'),
              _buildInfoRow('ພະນັກງານ:', user['staff_name'].toString()),
              _buildInfoRow('ເວລາປິດຮອບ:', closedAt),
              const Divider(height: 24),

              _buildSectionHeader('💰 ຍອດຂາຍ'),
              _buildInfoRow(
                'ຍອດຂາຍລວມ (Total Sales):',
                '${_currencyFormat.format(_safeParseDouble(sales['total_sales']))} ກີບ',
                isTotal: true,
              ),
              _buildInfoRow(
                'ຈຳນວນປີ້ (Total Tickets):',
                '${sales['total_tickets']} ໃບ',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                '  - ຍອດຜູ້ໃຫຍ່:',
                '${_currencyFormat.format(_safeParseDouble(sales['adult_sales']))} ກີບ',
              ),
              _buildInfoRow(
                '  - ຍອດເດັກນ້ອຍ:',
                '${_currencyFormat.format(_safeParseDouble(sales['child_sales']))} ກີບ',
              ),
              const Divider(height: 24),

              _buildSectionHeader('💳 ປະເພດການຈ່າຍເງິນ'),
              ...payments.map((payment) {
                final Map<String, dynamic> pMap =
                    payment as Map<String, dynamic>;
                return _buildInfoRow(
                  '  - ${pMap['method']}:',
                  '${_currencyFormat.format(_safeParseDouble(pMap['total']))} ກີບ',
                );
              }).toList(),
              const Divider(height: 24),

              _buildSectionHeader('🎠 ຂໍ້ມູນເຄື່ອງຫຼິ້ນ'),
              _buildInfoRow(
                'ຈຳນວນຫຼິ້ນທັງໝົດ:',
                '${rides['total_plays']} ຄັ້ງ',
              ),
              _buildInfoRow(
                '  - ຜູ້ໃຫຍ່ຫຼິ້ນ:',
                '${rides['adults_played']} ຄັ້ງ',
              ),
              _buildInfoRow(
                '  - ເດັກນ້ອຍຫຼິ້ນ:',
                '${rides['children_played']} ຄັ້ງ',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context)
              .pop(),
          child: const Text('ກັບຄືນ'),
        ),

        ElevatedButton(
          onPressed: () {
            _showConfirmDialog(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFF1A9A8B), 
            foregroundColor: Colors.white,
          ),
          child: const Text('ຢືນຢັນປິດກະ'),
        ),
      ],
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