import 'package:flutter/material.dart';

import '../models/new_visitor_ticket.dart';
import '../models/cart_item.dart';
import '../models/api_ticket_response.dart';
import '../services/newticket_api.dart'; // (Service ຂອງທ່ານ)
import './receipt_page.dart';

class PaymentQrView extends StatefulWidget {
  final double totalPrice;
  final List<CartItem> cart;
  final String paymentMethodCode;
  // [ແກ້ໄຂ 1] ຮັບຂໍ້ມູນ Visitor
  final String visitorFullName;
  final String visitorPhone;
  final String visitorGender;
  // final String visitorType; // <-- ລຶບອອກ

  const PaymentQrView({
    super.key,
    required this.totalPrice,
    required this.cart,
    required this.paymentMethodCode,
    // [ແກ້ໄຂ 2] ເພີ່ມໃນ Constructor
    required this.visitorFullName,
    required this.visitorPhone,
    required this.visitorGender,
    // required this.visitorType, // <-- ລຶບອອກ
  });

  @override
  State<PaymentQrView> createState() => _PaymentQrViewState();
}

class _PaymentQrViewState extends State<PaymentQrView> {
  final VisitorApi _visitorApi = VisitorApi();
  bool _isProcessing = false;

  // [ແກ້ໄຂ 3] ຟັງຊັນສຳລັບສ້າງ JSON
  Future<void> _handleConfirmPayment(BuildContext context) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final List<TicketDetail> ticketDetails = [];
    for (var item in widget.cart) {
      for (int i = 0; i < item.quantityAdult; i++) {
        ticketDetails.add(
          TicketDetail(ticketId: item.ticket.ticketId, visitorType: 'adult'),
        );
      }
      for (int i = 0; i < item.quantityChild; i++) {
        ticketDetails.add(
          TicketDetail(ticketId: item.ticket.ticketId, visitorType: 'child'),
        );
      }
    }

    // [ແກ້ໄຂ 4] ສ້າງ Payload
    final payload = NewVisitorTicket(
      visitorUid: 'UID-${DateTime.now().millisecondsSinceEpoch}',
      fullName: widget.visitorFullName,
      phone: widget.visitorPhone,
      gender: widget.visitorGender,

      // visitorType: widget.visitorType, // <-- ລຶບອອກ
      tickets: ticketDetails,
      paymentMethod: widget.paymentMethodCode,
      amountDue: widget.totalPrice.toInt(),
      amountPaid: widget.totalPrice.toInt(),
      changeAmount: 0,
      paymentTransactions: null,
    );

    // ... (Code try...catch... ຄືເກົ່າ)
    try {
      print('--- 💸 ສົ່ງ API (${widget.paymentMethodCode}) ---');
      final Map<String, dynamic> responseMap = await _visitorApi.sellDayPass(
        payload,
      );
      final ApiTicketResponse apiResponse = ApiTicketResponse.fromMap(
        responseMap,
      );

      print('--- ✅ API Response (ແທ້) ---');
      print('Purchase ID: ${apiResponse.purchaseId}');

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptPage(response: apiResponse),
        ),
      );
    } catch (e) {
      print("--- ❌ API Error ---");
      print(e.toString());
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text('ເກີດຂໍ້ຜິດພາດ: ${e.toString()}'),
          actions: [
            TextButton(
              child: const Text('ຕົກລົງ'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 150, color: Colors.grey[800]),
          const SizedBox(height: 16),
          const Text('ສະແກນ QR ເພື່ອຊຳລະເງິນ', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            '${widget.totalPrice.toStringAsFixed(0)} ກີບ',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  // (Helper)
  Widget _buildActionButtons(BuildContext context) {
    if (_isProcessing) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('ຍົກເລີກ'), // ยกเลิก
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _handleConfirmPayment(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A9A8B),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontFamily: 'Phetsarath_OT',
              ),
            ),
            child: const Text('ຢືນຢັນ'), // ยืนยัน
          ),
        ),
      ],
    );
  }
}
