import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../models/api_ticket_response.dart';

// (ທ່ານອາດຈະຕ້ອງ Import ບໍລິການ Print ຂອງທ່ານຢູ່ບ່ອນນີ້)
// import '../services/receipt_printer_service.dart';

class ReceiptPage extends StatefulWidget {
  final List<ApiTicketResponse> responses;
  // ⭐️ FIX 1: ລຶບ totalAmountPaid ອອກ, ເພາະຂໍ້ມູນນີ້ມີຢູ່ໃນ 'responses' ແລ້ວ
  // final double totalAmountPaid;

  const ReceiptPage({
    super.key,
    required this.responses,
    // required this.totalAmountPaid, // 👈 ລຶບອອກ
  });

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final currencyFormat = NumberFormat("#,##0", "en_US");
  // (ຕົວຢ່າງ: ປະກາດ service ຖ້າທ່ານມີ)
  // final ReceiptPrinterService _printerService = ReceiptPrinterService();

  // --- Logic ການກົດປຸ່ມ ---
  void _handlePrintAndClose() {
    // 1. (ຕົວຢ່າງ) ສັ່ງ Print
    // try {
    //   // 📍 Logic ໃນອະນາຄົດ:
    //   // await _printerService.printFinancialReceipt(widget.responses.first); // ໄປ Printer A
    //   // await _printerService.printTicketStub(widget.responses.first); // ໄປ Printer B
    // } catch (e) {
    //   log("Printing Error: $e");
    // }

    // 2. ສົ່ງສັນຍານ "ສຳເລັດ" (true) ກັບຄືນໄປ
    Navigator.of(context).pop(true);
  }

  // --- Build Logic ---
  @override
  Widget build(BuildContext context) {
    if (widget.responses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('ບໍ່ພົບຂໍ້ມູນໃບຮັບເງິນ')),
      );
    }

    final ApiTicketResponse response = widget.responses.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ໃບຮັບເງິນ (Receipt)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
      backgroundColor: Colors.grey[300],
      // ຫຸ້ມ Body ทั้งหมด ด้วย SingleChildScrollView
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            // 📍 NEW: ໃຊ້ Column ເພື່ອຈັດລຽງ 2 ໃບ + ປຸ່ມ
            children: [
              const SizedBox(height: 24), // ໄລຍະຫ່າງດ້ານເທິງ
              // --- 1. ໃບຮັບເງິນ (Financial Receipt) ---
              _buildFinancialReceipt(response),

              const SizedBox(height: 24), // ໄລຍະຫ່າງກາງ
              // --- 2. ປີ້ QR (Ticket Stub) ---
              _buildTicketStub(response),

              const SizedBox(height: 24), // ໄລຍະຫ່າງກ່ອນປຸ່ມ
              // --- 3. ປຸ່ມ Print ---
              _buildPrintButton(),

              const SizedBox(height: 24), // ໄລຍະຫ່າງດ້ານລຸ່ມ
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ທີ່ສ້າງໃໝ່ ---

  /// ⭐️ NEW WIDGET 1: ສະແດງສະເພາະໃບຮັບເງິນ (ການເງິນ)
  Widget _buildFinancialReceipt(ApiTicketResponse response) {
    return Container(
      width: 400, // ຂະໜາດໃບຮັບເງິນ
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(response), // ໃຊ້ Helper ເດີມ
          const SizedBox(height: 16),

          // ⭐️ FIX 2: ປ່ຽນໄປໃຊ້ `response.amountDue` (ຍອດທີ່ຕ້ອງຈ່າຍ)
          _buildInfoRow(
            'ລາຄາທັງໝົດ:',
            '${currencyFormat.format(response.amountDue)} ກີບ',
            isBold: true,
          ),
          const SizedBox(height: 8),

          // ⭐️ FIX 3: ເພີ່ມແຖວ "ເງິນທີ່ໄດ້ຮັບ" (ຍອດທີ່ຈ່າຍມາ)
          _buildInfoRow(
            'ເງິນທີ່ໄດ້ຮັບ:',
            '${currencyFormat.format(response.amountPaid)} ກີບ',
          ),
          const SizedBox(height: 8),

          // ⭐️ FIX 4: 'ເງິນທອນ' ຍັງຄືເກົ່າ (ຖືກຕ້ອງແລ້ວ)
          _buildInfoRow(
            'ເງິນທອນ:',
            '${currencyFormat.format(response.changeAmount)} ກີບ',
          ),
        ],
      ),
    );
  }

  /// ⭐️ NEW WIDGET 2: ສະແດງສະເພາະປີ້ QR (ສຳລັບເຂົ້າງານ)
  Widget _buildTicketStub(ApiTicketResponse response) {
    return Container(
      width: 400, // ຂະໜາດໃບຮັບເງິນ
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ຫົວຂໍ້ຂອງປີ້
          const Center(
            child: Text(
              'ປີ້ສຳລັບເຂົ້າເຄື່ອງຫຼິ້ນ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoRow(
            'ປະເພດປີ້:',
            'ຜູ້ໃຫຍ່ x ${response.adultCount}, ເດັກນ້ອຍ x ${response.childCount}',
          ),
          const Divider(height: 32, thickness: 1),

          // --- QR Code ---
          Center(child: _buildQrCode(response.qrCode)), // ໃຊ້ Helper ເດີມ

          const Divider(height: 32, thickness: 1),

          // --- ລາຍການເຄື່ອງຫຼິ້ນ ---
          const Text(
            'ປະເພດເຄື່ອງຫຼິ້ນ', // ປ່ຽນຄຳວ່າ 'ເຄື່ອງຫຼິ້ນ:' ເພື່ອໃຫ້ຄືກັບຮູບ
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16), // ເພີ່ມໄລຍະຫ່າງ
          // 🚀 ປ່ຽນມາໃຊ້ Widget ໃໝ່ທີ່ຈັດລຽງເປັນແບບ Column/Checklist
          _buildRideList(response.rideNames),
        ],
      ),
    );
  }

 
  Widget _buildPrintButton() {
    
    return Container(
      width: 400,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ), // ຈັດໃຫ້ປຸ່ມຢູ່ກາງ (ຖ້າ width ບໍ່ເຕັມ)
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

   
    const int itemsPerRow = 3;
    List<Widget> rows = [];

    final displayNames = rideNames;


    for (int i = 0; i < displayNames.length; i += itemsPerRow) {
      List<Widget> rowItems = [];
      for (int j = 0; j < itemsPerRow; j++) {
        int index = i + j;
        if (index < displayNames.length) {
          
          rowItems.add(
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayNames[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    const Text('O', style: TextStyle(fontSize: 16)), // ວົງມົນ
                  ],
                ),
              ),
            ),
          );
        } else {
          // ຖ້າບໍ່ມີຂໍ້ມູນໃຫ້ເຕີມແຖວໃຫ້ຄົບ 3 ດ້ວຍ SizedBox
          rowItems.add(const Expanded(child: SizedBox.shrink()));
        }
      }
      rows.add(
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowItems),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  // --- Helper Widgets ໂຕເກົ່າ (ບໍ່ໄດ້ແກ້ໄຂ) ---

  // Helper Widget ສຳລັບສ່ວນຫົວ
  Widget _buildHeader(ApiTicketResponse response) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ເລກທີໃບບິນ: ${response.purchaseId}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'ຜູ້ຂາຍ: vadsana',
            ), // ⚠️ ທ່ານອາດຈະຕ້ອງດຶງຊື່ຜູ້ຂາຍມາຈາກບ່ອນອື່ນ
          ],
        ),
        Text('ວັນທີ: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
      ],
    );
  }

  // Helper Widget ສຳລັບແຖວຂໍ້ມູນ
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

  // Helper Widget ສຳລັບສະແດງ QR (SVG)
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
}
