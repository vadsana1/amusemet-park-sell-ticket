// import 'dart.convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// (แก้ path 4 บรรทัดนี้ให้ตรงกับโปรเจกต์ของคุณ)
import '../models/new_visitor_ticket.dart';
import '../models/cart_item.dart';
import '../models/api_ticket_response.dart';
import './receipt_page.dart';
import '../services/newticket_api.dart'; // (Service ของคุณ)

class PaymentCashView extends StatefulWidget {
  final double totalPrice;
  final List<CartItem> cart;
  final String paymentMethodCode;
  // [เพิ่ม] 1. รับข้อมูล Visitor
  final String visitorFullName;
  final String visitorPhone;
  final String visitorGender;
  // final String visitorType; // <-- ลบออก

  const PaymentCashView({
    super.key,
    required this.totalPrice,
    required this.cart,
    required this.paymentMethodCode,
    // [เพิ่ม] 2. เพิ่มใน Constructor
    required this.visitorFullName,
    required this.visitorPhone,
    required this.visitorGender,
    // required this.visitorType, // <-- ลบออก
  });

  @override
  State<PaymentCashView> createState() => _PaymentCashViewState();
}

class _PaymentCashViewState extends State<PaymentCashView> {
  final VisitorApi _visitorApi = VisitorApi();
  bool _isProcessing = false;

  // ... (State, initState, dispose, Getters, Logic Functions ... เหมือนเดิม) ...
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
    _amountReceived = widget.totalPrice;
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
      _amountReceived = widget.totalPrice;
      _amountController.text = currencyFormat.format(_amountReceived);
    });
  }
  // --- [จบส่วนโค้ดเดิม] ---

  // --- [แก้ไข] ฟังก์ชันสำหรับสร้าง JSON และยืนยัน ---
  Future<void> _handleConfirmPayment() async {
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

    // [แก้ไข] สร้าง Payload โดยใช้ข้อมูลจริงจากฟอร์ม
    final payload = NewVisitorTicket(
      visitorUid: 'UID-${DateTime.now().millisecondsSinceEpoch}',
      fullName: widget.visitorFullName,
      phone: widget.visitorPhone,
      gender: widget.visitorGender,

      // visitorType: widget.visitorType, // <-- ลบออก
      tickets: ticketDetails,
      paymentMethod: widget.paymentMethodCode,
      amountDue: widget.totalPrice.toInt(),
      amountPaid: _amountReceived.toInt(),
      changeAmount: _calculatedChange.toInt(),
      paymentTransactions: cashDetailsList,
    );

    // --- ເອີ້ນໃຊ້ API ແທ້ ---
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

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    bool canConfirm = _amountReceived >= widget.totalPrice && !_isProcessing;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'ມູນຄ່າສິນຄ້າ: ${currencyFormat.format(widget.totalPrice)} ກີບ',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [_buildDenominationButtons(), _buildSummaryInfo()],
            ),
          ),
        ),
        _buildActionButtons(context, canConfirm),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildDenominationButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: _denominations.map((denomination) {
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
                    '${currencyFormat.format(denomination)}',
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
      }).toList(),
    );
  }

  Widget _buildSummaryInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
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
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isProcessing ? null : _clearAll,
            child: const Text(
              'ລ້າງ',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool canConfirm) {
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
              child: const Text('ຍົກເລີກ'), // ยกเลิก
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
                  : const Text('ຢືນຢັນ'), // ยืนยัน
            ),
          ),
        ],
      ),
    );
  }
}

// (คลาส ThousandsFormatter เหมือนเดิม)
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final intValue = int.tryParse(newValue.text.replaceAll(',', ''));
    if (intValue == null) {
      return oldValue;
    }
    final formatter = NumberFormat('#,##0', 'en_US');
    String newText = formatter.format(intValue);
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
