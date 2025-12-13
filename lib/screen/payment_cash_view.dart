import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer';

import '../models/new_visitor_ticket.dart';
import '../models/cart_item.dart';
import '../models/api_ticket_response.dart';
import './receipt_page.dart';
import '../services/newticket_api.dart';
import '../services/newticket_multiple_api.dart';
import '../utils/thousands_formatter.dart';

class PaymentCashView extends StatefulWidget {
  final double totalPrice;
  final List<CartItem> cart;
  final String paymentMethodCode;
  final String visitorFullName;
  final String visitorPhone;
  final String visitorGender;
  final int globalAdultQty;
  final int globalChildQty;
  final String visitorType;

  const PaymentCashView({
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
  State<PaymentCashView> createState() => _PaymentCashViewState();
}

class _PaymentCashViewState extends State<PaymentCashView> {
  final VisitorApi _visitorApi = VisitorApi();
  final SellDayPassMultipleApi _visitorApiB = SellDayPassMultipleApi();

  bool _isProcessing = false;

  final List<double> _denominations = const [
    1000,
    2000,
    5000,
    10000,
    20000,
    50000,
    100000,
  ];
  Map<double, int> _cashCounts = {};
  final currencyFormat = NumberFormat("#,##0", "en_US");
  final TextEditingController _amountController = TextEditingController();
  double _amountReceived = 0.0;

  @override
  void initState() {
    super.initState();
    _cashCounts = {for (var d in _denominations) d: 0};
    _amountReceived = 0.0;
    _amountController.text = currencyFormat.format(_amountReceived);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _calculatedChange {
    final change = _amountReceived - widget.totalPrice;
    return (change < 0) ? 0 : change;
  }

  void _updateFromButtons(double denomination, int change) {
    setState(() {
      int currentCount = _cashCounts[denomination] ?? 0;
      if (currentCount + change >= 0) {
        _cashCounts[denomination] = currentCount + change;
      }
      double totalFromButtons = 0;
      _cashCounts.forEach((d, c) => totalFromButtons += d * c);
      _amountReceived = totalFromButtons;
      _amountController.text = currencyFormat.format(_amountReceived);
    });
  }

  void _updateFromTextField(String value) {
    String cleanValue = value.replaceAll(RegExp(r'[,.]'), '');
    double newAmount = double.tryParse(cleanValue) ?? 0;
    setState(() {
      _amountReceived = newAmount;
      _cashCounts = {for (var d in _denominations) d: 0};
    });
  }

  void _clearAll() {
    setState(() {
      _cashCounts = {for (var d in _denominations) d: 0};
      _amountReceived = 0.0;
      _amountController.text = currencyFormat.format(_amountReceived);
    });
  }

  Future<void> _handleConfirmPayment() async {
    if (_amountReceived < widget.totalPrice) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ຈຳນວນເງິນທີ່ໄດ້ຮັບໜ້ອຍກວ່າລາຄາປີ້'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final List<CashDetail> cashDetailsList = [];
    _cashCounts.forEach((denomination, quantity) {
      if (quantity > 0) {
        cashDetailsList.add(
          CashDetail(denomination: denomination.toInt(), quantity: quantity),
        );
      }
    });

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

      final List<Map<String, dynamic>> cashPayload =
          cashDetailsList.map((cash) => cash.toMap()).toList();

      List<Map<String, dynamic>> ticketsPayload;
      final List<TicketDetail> ticketDetailsForResponseMapping = [];

      // --- Logic Block (ticketsPayload) ---
      if (totalPeople == 1) {
        log('--- ℹ️ Building Payload (API A - 1 object per Ride) ---');

        String visitorType = (widget.globalAdultQty == 1) ? 'adult' : 'child';

        ticketsPayload = [];
        for (var item in widget.cart) {
          var detail = TicketDetail(
            ticketId: item.ticket.ticketId,
            visitorType: visitorType,
            gender: widget.visitorGender,
          );
          ticketsPayload.add(detail.toMap());
          ticketDetailsForResponseMapping.add(detail);
        }
      } else {
        log('--- ℹ️ Building Payload (API B - 1 object per Person) ---');

        final List<int> allTicketIdsInCart =
            widget.cart.map((item) => item.ticket.ticketId).toSet().toList();

        ticketsPayload = [];

        for (int i = 0; i < widget.globalAdultQty; i++) {
          ticketsPayload.add({
            "visitor_type": "adult",
            "gender": widget.visitorGender,
            "ticket_id": allTicketIdsInCart, // 👈 ticket_id ເປັນ Array
          });
          ticketDetailsForResponseMapping
              .add(TicketDetail(ticketId: 0, visitorType: 'adult', gender: ''));
        }
        for (int i = 0; i < widget.globalChildQty; i++) {
          ticketsPayload.add({
            "visitor_type": "child",
            "gender": widget.visitorGender,
            "ticket_id": allTicketIdsInCart,
          });
          ticketDetailsForResponseMapping
              .add(TicketDetail(ticketId: 0, visitorType: 'child', gender: ''));
        }
      }

      final Map<String, dynamic> basePayload = {
        "tickets": ticketsPayload,
        "payment_method": widget.paymentMethodCode,
        "amount_due": widget.totalPrice.toInt(),
        "amount_paid": _amountReceived.toInt(),
        "change_amount": _calculatedChange.toInt(),
        "payment_transactions": cashPayload,
      };

      if (totalPeople == 1) {
        final Map<String, dynamic> flatPayload = {
          ...basePayload,
          ...visitorDetails,
        };
        log('Payload 1-Ticket (Flat) Sent: ${json.encode(flatPayload)}');
        log('Calling API (A): sellDayPass (ຕົວເດີມ)');

        final Map<String, dynamic> responseMap = await _visitorApi.sellDayPass(
          flatPayload,
        );
        log('--- ✅ Full API (A) Response ---: ${json.encode(responseMap)}');

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

        log('Payload Multiple (Nested) Sent: ${json.encode(nestedPayload)}');
        log('Calling API (B): sellDayPassMultiple (ຕົວໃໝ່)');

        final Map<String, dynamic> fullResponseMap =
            await _visitorApiB.sellDayPassMultiple(nestedPayload);

        log('--- ✅ Full API (B) Response ---: ${json.encode(fullResponseMap)}');

        final List<dynamic> responseList =
            fullResponseMap['purchases'] as List<dynamic>;

        if (responseList.length != ticketDetailsForResponseMapping.length) {
          throw Exception(
              "API response count (${responseList.length}) does not match sent payload count (${ticketDetailsForResponseMapping.length}).");
        }

        apiResponses = [];
        for (int i = 0; i < responseList.length; i++) {
          final responseData = responseList[i] as Map<String, dynamic>;
          final sentData = ticketDetailsForResponseMapping[i];
          final String visitorType = sentData.visitorType;

          apiResponses.add(
            ApiTicketResponse.fromMap(
              purchaseMap: responseData,
              rootMap: fullResponseMap,
              globalAdultQty: visitorType == 'adult' ? 1 : 0,
              globalChildQty: visitorType == 'child' ? 1 : 0,
            ),
          );
        }
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

  @override
  Widget build(BuildContext context) {
    bool canConfirm = _amountReceived >= widget.totalPrice && !_isProcessing;
    return Column(
      children: [
        const SizedBox(height: 12), // เพิ่ม margin ด้านบน
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ມູນຄ່າສິນຄ້າ: ${currencyFormat.format(widget.totalPrice)} ກີບ',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                _buildDenominationButtons(),
                _buildSummaryInfo(),
              ],
            ),
          ),
        ),
        _buildActionButtons(context, canConfirm),
      ],
    );
  }

  Widget _buildDenominationButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        ..._denominations.map((denomination) {
          final count = _cashCounts[denomination] ?? 0;
          return GestureDetector(
            onTap: _isProcessing
                ? null
                : () => _updateFromButtons(denomination, 1),
            onLongPress: _isProcessing
                ? null
                : () => _updateFromButtons(denomination, -1),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 100,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber[300]!, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      currencyFormat.format(denomination),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A9A8B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      child: Center(
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        // ปุ่มล้าง
        GestureDetector(
          onTap: _isProcessing ? null : _clearAll,
          child: Container(
            width: 100,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.clear_all, color: Colors.red, size: 24),
                const SizedBox(height: 4),
                Text(
                  'ລ້າງ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('ລວມຈ່າຍ:', style: TextStyle(fontSize: 18)),
              SizedBox(
                width: 180,
                child: TextFormField(
                  controller: _amountController,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  readOnly: _isProcessing,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A9A8B),
                  ),
                  decoration: const InputDecoration(
                    suffixText: ' ກີບ',
                    border: UnderlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    isDense: true,
                  ),
                  onChanged: _updateFromTextField,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsFormatter(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ເງິນທອນ:', style: TextStyle(fontSize: 18)),
              Text(
                '${currencyFormat.format(_calculatedChange)} ກີບ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool canConfirm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              onPressed: canConfirm ? _handleConfirmPayment : null,
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
                  : const Text('ຢືນຢັນ'),
            ),
          ),
        ],
      ),
    );
  }
}
