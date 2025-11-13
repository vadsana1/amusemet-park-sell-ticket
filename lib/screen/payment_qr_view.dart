import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer';

import '../models/new_visitor_ticket.dart'; 
import '../models/cart_item.dart';
import '../models/api_ticket_response.dart';
import './receipt_page.dart';

import '../services/newticket_api.dart';
import '../services/newticket_multiple_api.dart'; 

class PaymentQrView extends StatefulWidget {
  final double totalPrice;
  final List<CartItem> cart;
  final String paymentMethodCode;
  final String visitorFullName;
  final String visitorPhone;
  final String visitorGender;
  final int globalAdultQty;
  final int globalChildQty;
  final String visitorType;

  const PaymentQrView({
    super.key,
    required this.totalPrice,
    required this.cart,
    required this.paymentMethodCode,
    required this.visitorFullName,
    required this.visitorPhone,
    required this.visitorGender,
    required this.globalAdultQty,
    required this.globalChildQty,
    required this.visitorType,
  });

  @override
  State<PaymentQrView> createState() => _PaymentQrViewState();
}

class _PaymentQrViewState extends State<PaymentQrView> {
  final VisitorApi _visitorApi = VisitorApi();
  final SellDayPassMultipleApi _visitorApiB =
      SellDayPassMultipleApi(); 
  bool _isProcessing = false;
  final currencyFormat = NumberFormat("#,##0", "en_US");

  late TextEditingController _referenceIdController;
  late TextEditingController _bankBillNumberController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _referenceIdController = TextEditingController();
    _bankBillNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _referenceIdController.dispose();
    _bankBillNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final List<TicketDetail> ticketDetails = [];
    for (var item in widget.cart) {
      for (int i = 0; i < item.quantityAdult; i++) {
        ticketDetails.add(
          TicketDetail(
            ticketId: item.ticket.ticketId,
            visitorType: 'adult',
            gender: widget.visitorGender,
          ),
        );
      }
      for (int i = 0; i < item.quantityChild; i++) {
        ticketDetails.add(
          TicketDetail(
            ticketId: item.ticket.ticketId,
            visitorType: 'child',
            gender: widget.visitorGender,
          ),
        );
      }
    }

    int totalPeople = widget.globalAdultQty + widget.globalChildQty;
    if (totalPeople == 0) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      log(
        '--- 💸 ສົ່ງ API (${widget.paymentMethodCode}) - ($totalPeople ຄົນ) ---',
      );
      List<ApiTicketResponse> apiResponses = [];

      final Map<String, dynamic> visitorDetails = {
        "visitor_uid": const Uuid().v4(),
        "full_name": widget.visitorFullName,
        "phone": widget.visitorPhone,
        "gender": widget.visitorGender,
        "visitor_type": widget.visitorType,
      };

      final String referenceId = _referenceIdController.text;
      final String bankBillNumber = _bankBillNumberController.text;

      List<Map<String, dynamic>> ticketsPayload;
      if (totalPeople == 1) {
        log('ສ້າງ Payload (A) ແບບ int');
        ticketsPayload = ticketDetails.map((ticket) => ticket.toMap()).toList();
      } else {
        log('ສ້າງ Payload (B) ແບບ Array');
        ticketsPayload = ticketDetails.map((ticket) {
          final map = ticket.toMap();
          map['ticket_id'] = [map['ticket_id']];
          return map;
        }).toList();
      }

      final Map<String, dynamic> basePayload = {
        "tickets": ticketsPayload,
        "payment_method": widget.paymentMethodCode,
        "amount_due": widget.totalPrice.toInt(),
        "amount_paid": widget.totalPrice.toInt(), 
        "change_amount": 0, 
        "payment_transactions": [], 
        "transaction_ref_id": referenceId,
        "bank_bill_number": bankBillNumber,
      };

      if (totalPeople == 1) {
        final Map<String, dynamic> flatPayload = {
          ...basePayload,
          ...visitorDetails,
        };
        log('Payload 1-QR (API A) Sent: ${json.encode(flatPayload)}');
        log('Calling API (A): sellDayPass');

        final Map<String, dynamic> responseMap = await _visitorApi.sellDayPass(
          flatPayload,
        );

        final List<dynamic>? purchasesList =
            responseMap['purchases'] as List<dynamic>?;
        if (purchasesList == null || purchasesList.isEmpty) {
          throw Exception('API (A) did not return "purchases" list.');
        }
        final Map<String, dynamic> purchaseMap = purchasesList.first;

        apiResponses.add(
          ApiTicketResponse.fromMap(
            purchaseMap: purchaseMap, 
            rootMap: responseMap, 
            globalAdultQty: widget.globalAdultQty,
            globalChildQty: widget.globalChildQty,
          ),
        );
      } else {
        final Map<String, dynamic> nestedPayload = {
          ...basePayload,
          "visitor": visitorDetails,
        };
        log('Payload Multiple-QR (API B) Sent: ${json.encode(nestedPayload)}');
        log('Calling API (B): sellDayPassMultiple');

        final Map<String, dynamic> fullResponseMap = await _visitorApiB
            .sellDayPassMultiple(nestedPayload);

        final List<dynamic> responseList =
            fullResponseMap['purchases'] as List<dynamic>;

        apiResponses = responseList.map((map) {
          final responseData = map as Map<String, dynamic>;
          return ApiTicketResponse.fromMap(
            purchaseMap: responseData, 
            rootMap: fullResponseMap, 
            globalAdultQty: responseData['ticket_type'] == 'adult' ? 1 : 0,
            globalChildQty: responseData['ticket_type'] == 'child' ? 1 : 0,
          );
        }).toList();
      }

      log('--- ✅ API Response (ແທ້) ---');
      log('ໄດ້ QR ທັງໝົດ: ${apiResponses.length} ໃບ');

      if (!mounted) return;

      final bool? receiptResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptPage(responses: apiResponses),
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
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      TextFormField(
                        controller: _referenceIdController,
                        decoration: InputDecoration(
                          labelText: 'ເລກອ້າງອີງ/Transaction ID',
                          hintText: 'ກອກເລກທີ່ໄດ້ຈາກການໂອນ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'ກະລຸນາກອກເລກອ້າງອີງ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bankBillNumberController,
                        decoration: InputDecoration(
                          labelText: 'ເລກບິນທະນາຄານ',
                          hintText: 'ກອກເລກບິນທະນາຄານ (ຖ້າມີ)',
                          border: OutlineInputBorder(),
                        ),

                      ),
                      const SizedBox(height: 32),

                      Icon(
                        Icons.qr_code_scanner,
                        size: 100,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "ຈຳນວນເງິນທີ່ຕ້ອງຈ່າຍ:",
                        style: TextStyle(fontSize: 18),
                      ),
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
