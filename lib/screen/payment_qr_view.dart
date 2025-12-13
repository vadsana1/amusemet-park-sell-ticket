import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer';

import '../models/cart_item.dart';
import '../models/api_ticket_response.dart';
import './receipt_page.dart';

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
  // ใช้ API B (Multiple) เป็นหลัก เพื่อรองรับ Nested Visitor และ Array Ticket ID
  final SellDayPassMultipleApi _visitorApiMultiple = SellDayPassMultipleApi();

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

    int totalPeople = widget.globalAdultQty + widget.globalChildQty;
    if (totalPeople == 0) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      log(
        '--- 💸 กำลังส่งข้อมูล (QR: ${widget.paymentMethodCode}) - ($totalPeople คน) ---',
      );

      // 1. เตรียม Visitor Object
      final Map<String, dynamic> visitorData = {
        "visitor_uid": const Uuid().v4(),
        "full_name": widget.visitorFullName,
        "phone": widget.visitorPhone,
        "gender": widget.visitorGender,
        "visitor_type": widget.visitorType,
      };

      // 2. เตรียม Ticket Payload (ใช้ Logic เดียวกับหน้า Cash)
      // รวบ ID ทุกใบในตะกร้า เป็น List เดียวกัน [5, 2]
      final List<int> allTicketIdsInCart =
          widget.cart.map((item) => item.ticket.ticketId).toSet().toList();

      List<Map<String, dynamic>> ticketsPayload = [];
      // สร้างตัวช่วย Mapping เพื่อเช็ค Type ตอน Response กลับมา
      final List<String> expectedTypes = [];

      // วนลูปสร้างตั๋วให้ผู้ใหญ่ทุกคน (ทุกคนได้ Bundle ID เหมือนกัน)
      for (int i = 0; i < widget.globalAdultQty; i++) {
        ticketsPayload.add({
          "visitor_type": "adult",
          "gender": widget.visitorGender,
          "ticket_id": allTicketIdsInCart, // ส่งเป็น Array [5, 2]
        });
        expectedTypes.add('adult');
      }

      // วนลูปสร้างตั๋วให้เด็กทุกคน
      for (int i = 0; i < widget.globalChildQty; i++) {
        ticketsPayload.add({
          "visitor_type": "child",
          "gender": widget.visitorGender,
          "ticket_id": allTicketIdsInCart, // ส่งเป็น Array [5, 2]
        });
        expectedTypes.add('child');
      }

      // 3. เตรียม Payment Transactions (ส่วนของ QR)
      List<Map<String, String>> paymentTransactions = [];

      if (_referenceIdController.text.isNotEmpty) {
        paymentTransactions.add({
          "transaction_ref1": _referenceIdController.text,
        });
      }

      if (_bankBillNumberController.text.isNotEmpty) {
        paymentTransactions.add({
          "transaction_ref2": _bankBillNumberController.text,
        });
      }

      // 4. รวมร่าง JSON Payload
      final Map<String, dynamic> fullPayload = {
        "visitor": visitorData,
        "tickets": ticketsPayload,
        "payment_method": widget.paymentMethodCode,
        "amount_due": widget.totalPrice.toInt(),
        "amount_paid": widget.totalPrice.toInt(),
        "change_amount": 0,
        "payment_transactions": paymentTransactions,
      };

      log('FINAL PAYLOAD (QR): ${json.encode(fullPayload)}');

      // 5. ส่ง API
      final Map<String, dynamic> fullResponseMap =
          await _visitorApiMultiple.sellDayPassMultiple(fullPayload);

      // 6. จัดการ Response
      final List<dynamic> responseList =
          fullResponseMap['purchases'] as List<dynamic>;

      // เช็คว่าจำนวนที่ได้กลับมา ตรงกับที่ส่งไปไหม
      if (responseList.length != expectedTypes.length) {
        log(
          "Warning: Response count (${responseList.length}) != Request count (${expectedTypes.length})",
        );
      }

      List<ApiTicketResponse> apiResponses = [];
      for (int i = 0; i < responseList.length; i++) {
        final responseData = responseList[i] as Map<String, dynamic>;

        // ใช้ Type จากที่เรา Loop ไว้ หรือถ้า API แม่นยำใช้จาก API ก็ได้
        // ในที่นี้ใช้ logic เดียวกับ Cash คือ map กลับมาตาม index
        String type = (i < expectedTypes.length)
            ? expectedTypes[i]
            : responseData['ticket_type'] ?? 'adult';

        // Double Check จาก API Response
        if (responseData.containsKey('ticket_type')) {
          type = responseData['ticket_type'];
        }

        apiResponses.add(
          ApiTicketResponse.fromMap(
            purchaseMap: responseData,
            rootMap: fullResponseMap,
            globalAdultQty: type == 'adult' ? 1 : 0,
            globalChildQty: type == 'child' ? 1 : 0,
          ),
        );
      }

      log('--- ✅ สำเร็จ (QR) ได้ตั๋ว: ${apiResponses.length} ใบ ---');

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
            'เกิดข้อผิดพลาด: ${e.toString().split("Exception: ").last}',
          ),
          actions: [
            TextButton(
              child: const Text('ตกลง'),
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

  // --- Build Method (UI ส่วนเดิม ไม่เปลี่ยนแปลง) ---
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
                        decoration: const InputDecoration(
                          labelText: 'เลขที่อ้างอิง/Transaction ID',
                          hintText: 'กรอกเลขที่ได้จากการโอน',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกเลขที่อ้างอิง';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bankBillNumberController,
                        decoration: const InputDecoration(
                          labelText: 'เลขบิลธนาคาร',
                          hintText: 'กรอกเลขบิลธนาคาร (ถ้ามี)',
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
                        "จำนวนเงินที่ต้องชำระ:",
                        style: TextStyle(fontSize: 18),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${currencyFormat.format(widget.totalPrice)} กีบ',
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
              child: const Text('ยกเลิก'),
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
                  : const Text('ยืนยัน (QR)'),
            ),
          ),
        ],
      ),
    );
  }
}
