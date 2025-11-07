import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer';

// (ກວດສອບ Path ໃຫ້ຖືກຕ້ອງ)
// import '../models/new_visitor_ticket.dart';
import '../models/cart_item.dart';
import '../models/api_ticket_response.dart';
import './receipt_page.dart';
// ⚠️ ປ່ຽນຊື່ໄຟລ໌ນີ້ ໃຫ້ຕົງກັບໄຟລ໌ API ຂອງທ່ານ (ເຊັ່ນ: newticket_api.dart)
import '../services/newticket_api.dart';

class PaymentQrView extends StatefulWidget {
 final double totalPrice;
 final List<CartItem> cart;
 final String paymentMethodCode; // (เช่น "QR")
 final String visitorFullName;
 final String visitorPhone;
 final String visitorGender;

  // 🎯 [FIX 1] ຮັບຈຳນວນຄົນ (Global) ຈາກ PaymentPage (ໜ້າແມ່)
  final int globalAdultQty;
  final int globalChildQty;

 const PaymentQrView({
  super.key,
  required this.totalPrice,
  required this.cart,
  required this.paymentMethodCode,
  required this.visitorFullName,
  required this.visitorPhone,
  required this.visitorGender,
    // 🎯 [FIX 1] ຮັບຄ່າ 2 ອັນນີ້
    required this.globalAdultQty,
    required this.globalChildQty,
 });

 @override
 State<PaymentQrView> createState() => _PaymentQrViewState();
}

class _PaymentQrViewState extends State<PaymentQrView> {
 final VisitorApi _visitorApi = VisitorApi();
 bool _isProcessing = false;
  final currencyFormat = NumberFormat("#,##0", "en_US");

  // --- 🎯 [FIX 2] ຟັງຊັນສຳລັບສ້າງ JSON ແລະ ຢືນຢັນ (Logic ດຽວກັນ) ---
 Future<void> _handleConfirmPayment() async {
  if (_isProcessing) return;
  setState(() => _isProcessing = true);

    // 🎯 [FIX 2.2] ນັບຈຳນວນຄົນຈາກ Global
  int totalPeople = widget.globalAdultQty + widget.globalChildQty; // 👈 ຈະໄດ້ 1
  if (totalPeople == 0) {
   setState(() => _isProcessing = false);
   return;
  }

    // 🎯 [FIX 2.3] ສ້າງ List ID ຂອງປີ້ທັງໝົດ
    final List<int> ticketIds = widget.cart
        .map((item) => item.ticket.ticketId)
        .toList(); // 👈 ຈະໄດ້ [id1, id2, id3]

  // --- 4. ສ້າງ Payload ໃຫ້ຕົງກັບ API (A) ເທົ່ານັ້ນ ---
  try {
 	log('--- 💸 ສົ່ງ API (${widget.paymentMethodCode}) - ($totalPeople ຄົນ) ---');
 	List<ApiTicketResponse> apiResponses = [];

 	final Map<String, dynamic> visitorDetails = {
 	  "visitor_uid": const Uuid().v4(),
 	  "full_name": widget.visitorFullName,
 	  "phone": widget.visitorPhone,
 	  "gender": widget.visitorGender,
 	};

      // 🎯 [FIX 2.4] ສ້າງ 'tickets' payload ສຳລັບ API (A)
      final List<Map<String, dynamic>> ticketsPayload = [];
      for(int i = 0; i < widget.globalAdultQty; i++) {
        ticketsPayload.add({
          "ticket_id": ticketIds.first, 
          "visitor_type": "adult",
          "gender": widget.visitorGender
        });
      }
      for(int i = 0; i < widget.globalChildQty; i++) {
        ticketsPayload.add({
          "ticket_id": ticketIds.first,
          "visitor_type": "child",
          "gender": widget.visitorGender
        });
      }

      // 🎯 [FIX 2.5] ສ້າງ Payload ລວມສຳລັບ API (A)
 	  final Map<String, dynamic> flatPayload = {
        ...visitorDetails, 
        "tickets": ticketsPayload,
        "payment_method": widget.paymentMethodCode,
 	"amount_due": widget.totalPrice.toInt(),
 	"amount_paid": widget.totalPrice.toInt(), // 👈 QR ຈ່າຍເຕັມ
 	"change_amount": 0, // 👈 ບໍ່ມີເງິນທອນ
 	"payment_transactions": [], // 👈 ບໍ່ມີລາຍລະອຽດເງິນສົດ
        "ticket_ids": ticketIds, 
        "quantity_adult": widget.globalAdultQty,
        "quantity_child": widget.globalChildQty,
 	  };

      // 🎯 [FIX 2.6] ເອີ້ນ API (A) ໂດຍກົງ
 	  log('Payload 1-QR (API A) Sent: ${json.encode(flatPayload)}');
 	  log('Calling API (A): sellDayPass');
 	  final Map<String, dynamic> responseMap = await _visitorApi.sellDayPass(
 	flatPayload,
   );
  
      // 🎯 [FIX ERROR: Line 208]
      // ປ່ຽນການເອີ້ນ FromMap ໃຫ້ສົ່ງຈຳນວນຄົນໄປນຳ
 	  ApiTicketResponse ticketResponse = ApiTicketResponse.fromMap(
    		responseMap, // 👈 ໂຕ JSON
    		globalAdultQty: widget.globalAdultQty, // 👈 ສົ່ງຈຳນວນຜູ້ໃຫຍ່
    		globalChildQty: widget.globalChildQty, // 👈 ສົ່ງຈຳນວນເດັກນ້ອຍ
    	);
 	  apiResponses.add(ticketResponse); // 👈 ຈະໄດ້ 1 QR

 	  log('--- ✅ API Response (ແທ້) ---');
 	  log('ໄດ້ QR ທັງໝົດ: ${apiResponses.length} ໃບ'); // 👈 ຄວນຈະເປັນ 1

 	  if (!mounted) return;

 	  final bool? receiptResult = await Navigator.push(
 	context,
 	MaterialPageRoute(
 	  builder: (context) => ReceiptPage(
 	responses: apiResponses,
 	
   ),
 ),
 	  );

 	  if (receiptResult == true) {
 	if (mounted) {
 	  Navigator.of(context).pop(true); 
 	}
 	  }
 	} catch (e) {
 	  log("--- ❌ API Error ---");
 	  log(e.toString());
 	  if (!mounted) return;
 	  showDialog(
 	context: context,
 	builder: (ctx) => AlertDialog(
 	  title: const Text('Error'),
 	  content: Text(
 	'ເກີດຂໍ້ຜິດພາດ: ${e.toString().split("Exception: ").last}',
   ),
   actions: [
 	TextButton(
 	  child: const Text('ຕົກລົງ'),
 	  onPressed: () => Navigator.of(ctx).pop(),
 	),
   ],
 ),
   );
 	} finally {
 	  if (mounted) {
 	setState(() => _isProcessing = false);
 	  }
 	}
 }

  // --- Build Method ---
 @override
 Widget build(BuildContext context) {
 	return Column(
 	  children: [
 	Expanded(
 	  child: Center(
 	child: Column(
 	  mainAxisAlignment: MainAxisAlignment.center,
 	  children: [
 	Icon(Icons.qr_code_scanner, size: 100, color: Colors.grey[700]),
 	const SizedBox(height: 20),
 	const Text("ກຽມຢືນຢັນການຊຳລະ QR", style: TextStyle(fontSize: 18)),
 	Padding(
 	  padding: const EdgeInsets.all(8.0),
 	  child: Text(
 	'${currencyFormat.format(widget.totalPrice)} ກີບ',
 	style: const TextStyle(
 	  fontSize: 22,
 	  fontWeight: FontWeight.bold,
 	  color: Color(0xFF1A9A8B),
 	),
   ),
 ),
 	  ],
 	),
   ),
 	),
 	_buildActionButtons(context),
 	  ],
 	);
 }

 Widget _buildActionButtons(BuildContext context) {
 	return Padding(
 	  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
 	  child: Row(
 	children: [
 	  Expanded(
 	child: OutlinedButton(
 	  onPressed: _isProcessing
 	? null
 	: () {
 	  Navigator.pop(context);
 	},
 	  style: OutlinedButton.styleFrom(
 	padding: const EdgeInsets.symmetric(vertical: 16),
   ),
   child: const Text('ຍົກເລີກ'),
 ),
   ),
   const SizedBox(width: 16),
   Expanded(
 	child: ElevatedButton(
 	  onPressed: _isProcessing ? null : _handleConfirmPayment,
 	  style: ElevatedButton.styleFrom(
 	backgroundColor: const Color(0xFF1A9A8B),
 	padding: const EdgeInsets.symmetric(vertical: 16),
 	textStyle: const TextStyle(
 	  fontSize: 16,
 	  fontFamily: 'Phetsarath_OT',
 	),
   ),
   child: _isProcessing
 	? const SizedBox(
 	width: 24,
 	height: 24,
 	child: CircularProgressIndicator(
 	  color: Colors.white,
 	  strokeWidth: 3,
 	),
 )
 	: const Text('ຢືນຢັນ (QR)'),
 ),
   ),
 	],
   ),
 	);
 }
}