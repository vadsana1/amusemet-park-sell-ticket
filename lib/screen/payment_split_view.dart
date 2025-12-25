import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/cart_item.dart';
import '../models/api_ticket_response.dart';
import './receipt_page.dart';
import '../services/newticket_api.dart';
import '../services/newticket_multiple_api.dart';
import '../utils/url_helper.dart' show storage;

class PaymentSplitView extends StatefulWidget {
  final double totalPrice;
  final List<CartItem> cart;
  final String paymentMethodCode;
  final String visitorFullName;
  final String visitorPhone;
  final String visitorGender;
  final int globalAdultQty;
  final int globalChildQty;
  final String visitorType;

  const PaymentSplitView({
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
  State<PaymentSplitView> createState() => _PaymentSplitViewState();
}

class _PaymentSplitViewState extends State<PaymentSplitView> {
  // API สำหรับ single-split (ตั๋วเดียว)
  final VisitorApi _visitorApi = VisitorApi();
  // API สำหรับ multiple-split (หลายตั๋ว)
  final SellDayPassMultipleApi _visitorApiMultiple = SellDayPassMultipleApi();
  // 🔧 ใช้ global storage จาก url_helper แทน

  static final platform =
      const MethodChannel('com.example.amusemet_park_sell_ticket/dual_screen');

  bool _isProcessing = false;
  final currencyFormat = NumberFormat("#,##0", "en_US");

  late TextEditingController _cashInputController;
  late TextEditingController _transferRefController;
  final _formKey = GlobalKey<FormState>();

  double _cashAmount = 0.0;
  double _transferAmount = 0.0;
  int _refNumberMinLength = 6; // default minimum length

  // สีหลัก (ปรับให้ดู Soft ลง)
  final Color _primaryColor = const Color(0xFF1A9A8B);

  @override
  void initState() {
    super.initState();
    _transferRefController = TextEditingController();
    _cashInputController = TextEditingController();
    _transferAmount = widget.totalPrice;

    _cashInputController.addListener(_calculateRemaining);
    _transferRefController.addListener(() {
      log('📝 Ref text changed: ${_transferRefController.text} (length: ${_transferRefController.text.length})');
      setState(() {}); // Rebuild to update button state
    });

    log('🚀 PaymentSplitView initState - Initial _refNumberMinLength: $_refNumberMinLength');

    // Load ref min length first, then show QR
    _loadRefMinLength().then((_) {
      log('✅ _loadRefMinLength completed');
      _showQrOnCustomerScreen();
    });
  }

  Future<void> _loadRefMinLength() async {
    log('⏳ Loading ref_number_min_length from storage...');
    final refLength = await storage.read(key: 'ref_number_min_length');
    log('📦 Read value from storage: "$refLength"');
    if (mounted) {
      setState(() {
        _refNumberMinLength = int.tryParse(refLength ?? '6') ?? 6;
      });
      log('✅ Ref Number Min Length loaded: $_refNumberMinLength');
    }
  }

  @override
  void dispose() {
    _cashInputController.removeListener(_calculateRemaining);
    _cashInputController.dispose();
    _transferRefController.dispose();
    _resetCustomerScreen();
    super.dispose();
  }

  void _calculateRemaining() {
    String text = _cashInputController.text.replaceAll(',', '');
    double cash = double.tryParse(text) ?? 0.0;
    setState(() {
      _cashAmount = cash;
      _transferAmount = widget.totalPrice - _cashAmount;
      if (_transferAmount < 0) _transferAmount = 0;
    });
  }

  bool _canConfirm() {
    // กำลัง process อยู่ → ไม่ให้กด
    if (_isProcessing) return false;

    // เงินสดเกิน/เท่ากับราคารวม → ไม่ให้กด (ไม่ต้องใช้โอนเงิน)
    if (_cashAmount >= widget.totalPrice) return false;

    // ถ้ามียอดโอนเงิน ต้องกรอก Ref ให้ครบตามจำนวน
    if (_transferAmount > 0) {
      final refText = _transferRefController.text.trim();
      log('🔍 DEBUG: Ref Length = ${refText.length}, Min Required = $_refNumberMinLength');
      if (refText.length < _refNumberMinLength) {
        log('❌ Ref ไม่ครบ: ${refText.length} < $_refNumberMinLength');
        return false; // Ref ไม่ครบ → ไม่ให้กด
      }
      log('✅ Ref ครบแล้ว: ${refText.length} >= $_refNumberMinLength');
    }

    return true;
  }

  Future<void> _showQrOnCustomerScreen() async {
    try {
      final ByteData data =
          await rootBundle.load('assets/images/bank_qr_cropped.jpeg');
      final Uint8List imageBytes = data.buffer.asUint8List();
      await platform.invokeMethod('showImage', {'imageBytes': imageBytes});
    } catch (e) {
      log("Error showImage: $e");
    }
  }

  Future<void> _resetCustomerScreen() async {
    try {
      await platform.invokeMethod('clearScreen');
    } catch (e) {
      log("Error clearScreen: $e");
    }
  }

  Future<void> _handleConfirmPayment() async {
    print('🔔 CONFIRM BUTTON CLICKED');
    log('🔔 CONFIRM BUTTON CLICKED');

    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      log('❌ Form validation failed');
      return;
    }

    double totalPaid = _cashAmount + _transferAmount;
    print(
        '💰 Cash: $_cashAmount, Transfer: $_transferAmount, Total Paid: $totalPaid');
    log('💰 Cash: $_cashAmount, Transfer: $_transferAmount, Total Paid: $totalPaid');

    // ยอมให้ขาดได้นิดหน่อยเรื่องทศนิยม (เช่น 0.01)
    if (totalPaid < widget.totalPrice - 1) {
      log('⚠️ Incomplete amount: $totalPaid < ${widget.totalPrice}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('⚠️ ຍອດເງິນຍັງບໍ່ຄົບຖ້ວນ (Incomplete Amount)')),
      );
      return;
    }

    if (_isProcessing) {
      log('⏳ Already processing, skipping...');
      return;
    }

    log('✅ Starting payment process...');
    setState(() => _isProcessing = true);

    try {
      log('🎫 Building payment payload for multiple-split...');

      // สร้าง tickets payload แบบจัดกลุ่ม: ticket_id เป็น array
      Map<String, Map<String, dynamic>> ticketsGrouped = {};

      for (var cartItem in widget.cart) {
        int ticketId = cartItem.ticket.ticketId;

        // จัดกลุ่มตั๋วผู้ใหญ่
        if (cartItem.quantityAdult > 0) {
          String key = 'adult_${widget.visitorGender}';
          if (!ticketsGrouped.containsKey(key)) {
            ticketsGrouped[key] = {
              "ticket_id": <int>[],
              "visitor_type": "adult",
              "gender": widget.visitorGender
            };
          }
          for (int i = 0; i < cartItem.quantityAdult; i++) {
            (ticketsGrouped[key]!["ticket_id"] as List<int>).add(ticketId);
          }
        }

        // จัดกลุ่มตั๋วเด็ก
        if (cartItem.quantityChild > 0) {
          String key = 'child_${widget.visitorGender}';
          if (!ticketsGrouped.containsKey(key)) {
            ticketsGrouped[key] = {
              "ticket_id": <int>[],
              "visitor_type": "child",
              "gender": widget.visitorGender
            };
          }
          for (int i = 0; i < cartItem.quantityChild; i++) {
            (ticketsGrouped[key]!["ticket_id"] as List<int>).add(ticketId);
          }
        }
      }

      List<Map<String, dynamic>> ticketsPayload =
          ticketsGrouped.values.toList();
      log('🎫 Tickets payload (grouped): ${json.encode(ticketsPayload)}');

      List<Map<String, dynamic>> paymentsList = [];
      if (_cashAmount > 0) {
        log('💵 Adding CASH payment: $_cashAmount');
        paymentsList.add({
          "payment_method": "CASH",
          "amount": _cashAmount,
          "details": {"denominations": []}
        });
      }
      if (_transferAmount > 0) {
        log('🏦 Adding BANKTF payment: $_transferAmount, Ref: ${_transferRefController.text}');
        paymentsList.add({
          "payment_method": "BANKTF",
          "amount": _transferAmount,
          "details": {
            "provider": "BCEL_ONE",
            "transaction_ref1": _transferRefController.text,
            "transaction_ref2": ""
          }
        });
      }

      final Map<String, dynamic> fullPayload = {
        "visitor": {
          "visitor_uid": const Uuid().v4(),
          "full_name": widget.visitorFullName,
          "phone": widget.visitorPhone,
          "gender": widget.visitorGender,
          "visitor_type": widget.visitorType
        },
        "tickets": ticketsPayload,
        "order_summary": {
          "amount_due": widget.totalPrice.toInt(),
          "amount_paid": totalPaid.toInt(),
          "change_amount": (totalPaid - widget.totalPrice).toInt()
        },
        "payments": paymentsList
      };

      // 🔍 Log ข้อมูลที่ส่งไป API
      log('--- 📤 SPLIT PAYMENT REQUEST ---');
      log('Payload: ${json.encode(fullPayload)}');

      Map<String, dynamic> fullResponseMap;

      // ตรวจสอบว่ามีหลายตั๋วหรือไม่
      if (widget.cart.length > 1 || ticketsPayload.length > 1) {
        // ใช้ multiple-split API สำหรับหลายตั๋ว
        log('🌐 Calling API: sellDayPassMultipleSplit (multiple tickets)...');
        fullResponseMap =
            await _visitorApiMultiple.sellDayPassMultipleSplit(fullPayload);
      } else {
        // ใช้ single-split API สำหรับตั๋วเดียว
        log('🌐 Calling API: sellDayPassSplit (single ticket)...');
        // ต้องปรับ payload สำหรับ single-split
        final Map<String, dynamic> singlePayload = {
          "visitor_uid": fullPayload["visitor"]["visitor_uid"],
          "full_name": fullPayload["visitor"]["full_name"],
          "phone": fullPayload["visitor"]["phone"],
          "gender": fullPayload["visitor"]["gender"],
          "tickets": ticketsPayload.expand((group) {
            List<int> ticketIds = group["ticket_id"] as List<int>;
            return ticketIds.map((id) =>
                {"ticket_id": id, "visitor_type": group["visitor_type"]});
          }).toList(),
          "order_summary": fullPayload["order_summary"],
          "payments": fullPayload["payments"]
        };
        log('Single payload: ${json.encode(singlePayload)}');
        fullResponseMap = await _visitorApi.sellDayPassSplit(singlePayload);
      }

      // 🔍 Log ข้อมูลที่ได้จาก API
      log('--- 📥 SPLIT PAYMENT RESPONSE ---');
      log('Response: ${json.encode(fullResponseMap)}');

      log('📦 Processing API response...');
      List<ApiTicketResponse> apiResponses = [];
      if (fullResponseMap.containsKey('purchases')) {
        final List<dynamic> responseList =
            fullResponseMap['purchases'] as List<dynamic>;
        log('✅ Found ${responseList.length} purchases in response');
        for (var item in responseList) {
          apiResponses.add(ApiTicketResponse.fromMap(
            purchaseMap: item,
            rootMap: fullResponseMap,
            globalAdultQty: 0,
            globalChildQty: 0,
          ));
        }
      } else {
        log('⚠️ No purchases key found in response');
      }

      if (!mounted) {
        log('⚠️ Widget not mounted, stopping...');
        return;
      }

      log('🧾 Navigating to ReceiptPage with ${apiResponses.length} responses...');
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ReceiptPage(responses: apiResponses)),
      );

      log('🧾 User returned from receipt page - staying on payment page');
    } catch (e) {
      log('❌ ERROR in _handleConfirmPayment: $e');
      log('❌ Stack trace: ${StackTrace.current}');
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text('${e.toString().replaceAll("Exception:", "")}'),
          actions: [
            TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop()),
          ],
        ),
      );
    } finally {
      log('🏁 Payment process finished, resetting _isProcessing flag');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ใช้ SingleChildScrollView ครอบทั้งหมด เพื่อแก้ปัญหา Keyboard ทับ
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. ส่วนหัว: ยอดรวม (ทำให้เล็กลง และอยู่ใน Flow เดียวกัน)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("ຍອດລວມທັງໝົດ:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '${currencyFormat.format(widget.totalPrice)} ກີບ',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Input: เงินสด
              const Text("1. ຮັບເງິນສົດ (Cash)",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cashInputController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'ປ້ອນຈຳນວນເງິນ',
                  suffixText: 'ກີບ',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),

              const SizedBox(height: 24),

              // 3. ส่วนแสดงยอดคงเหลือ และ ช่องกรอก Ref (โชว์เมื่อยอดโอน > 0)
              if (_transferAmount > 0) ...[
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("2. ຍອດຄ້າງຊຳລະ (Balance):",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${currencyFormat.format(_transferAmount)} ກີບ',
                            style: const TextStyle(
                              fontSize: 18, // ขนาดกำลังดี ไม่ใหญ่เกิน
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      TextFormField(
                        controller: _transferRefController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText: 'ເລກທີອ້າງອີງ (Ref No.)',
                          hintText:
                              'Scan QR ແລະ ໃສ່ເລກ Ref ($_refNumberMinLength ຕົວຂື້ນໄປ)',
                          prefixIcon: const Icon(Icons.qr_code),
                          filled: true,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        validator: (value) {
                          if (_transferAmount > 0) {
                            if (value == null || value.isEmpty) {
                              return 'ກະລຸນາປ້ອນເລກ Ref';
                            }
                            if (value.length < _refNumberMinLength) {
                              return 'ເລກ Ref ຕ້ອງມີຢ່າງໜ້ອຍ $_refNumberMinLength ຕົວ';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text("ຊຳລະເງິນຄົບຖ້ວນ (Paid in Full)",
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // 4. ปุ่ม Action (วางต่อท้ายเลย ไม่ทับจอ)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isProcessing ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('ຍົກເລີກ'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      // ปิดปุ่มถ้า: กำลัง process, เงินสดเกิน/เท่ากับราคารวม, หรือ Ref ไม่ครบ
                      onPressed: _canConfirm() ? _handleConfirmPayment : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('ຢືນຢັນ',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),

              // เพิ่มพื้นที่ว่างด้านล่างเผื่อคีย์บอร์ดดันขึ้นมาอีกนิดหน่อย
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
