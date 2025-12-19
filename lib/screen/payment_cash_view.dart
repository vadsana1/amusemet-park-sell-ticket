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
  bool _isTransferMode = false; // Transfer mode

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
  final TextEditingController _transferRefController = TextEditingController();
  final TextEditingController _transferAmountController =
      TextEditingController();
  double _amountReceived = 0.0;
  double _transferAmount = 0.0;

  final GlobalKey _refFieldKey = GlobalKey(); // Key for Ref field
  final ScrollController _scrollController =
      ScrollController(); // Controller for scroll

  @override
  void initState() {
    super.initState();
    _cashCounts = {for (var d in _denominations) d: 0};
    _amountReceived = 0.0;
    _amountController.text = currencyFormat.format(_amountReceived);
    // ທุกครั้งที่กรอก Ref ให้ rebuild เพื่อ update ปุ่มยืนยัน
    _transferRefController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transferRefController.dispose();
    _transferAmountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleTransferMode() {
    setState(() {
      _isTransferMode = !_isTransferMode;
      if (!_isTransferMode) {
        _transferAmount = 0.0;
        _transferRefController.clear();
        _transferAmountController.clear();
      } else {
        // ตั้งค่าเริ่มต้นให้โอนเต็มจำนวน
        _transferAmount = widget.totalPrice - _amountReceived;
        if (_transferAmount < 0) _transferAmount = 0;
        _transferAmountController.text = currencyFormat.format(_transferAmount);
      }
    });
  }

  void _updateTransferAmount(String value) {
    String cleanValue = value.replaceAll(RegExp(r'[,.]'), '');
    double newAmount = double.tryParse(cleanValue) ?? 0;
    setState(() {
      _transferAmount = newAmount;
    });
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

      // อัพเดตยอดโอนเมื่ออยู่ในโหมดโอน
      if (_isTransferMode) {
        _transferAmount = widget.totalPrice - _amountReceived;
        if (_transferAmount < 0) _transferAmount = 0;
        _transferAmountController.text = currencyFormat.format(_transferAmount);
      }
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

  // ฟังก์ชันสำหรับ Split Payment (CASH + BANKTF)
  Future<void> _handleSplitPayment() async {
    try {
      log('🎫 Building split payment payload...');

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

      // สร้าง payments list
      List<Map<String, dynamic>> paymentsList = [];
      if (_amountReceived > 0) {
        log('💵 Adding CASH payment: $_amountReceived');

        // สร้าง denominations list จากปุ่มที่กด
        List<Map<String, dynamic>> denominations = [];
        _cashCounts.forEach((denomination, quantity) {
          if (quantity > 0) {
            denominations.add({
              "value": denomination.toInt(), // ใช้ "value" แทน "denomination"
              "quantity": quantity
            });
          }
        });

        paymentsList.add({
          "payment_method": "CASH",
          "amount": _amountReceived.toInt(),
          "details": {"denominations": denominations}
        });
      }

      if (_transferAmount > 0) {
        log('🏦 Adding BANKTF payment: $_transferAmount, Ref: ${_transferRefController.text}');
        paymentsList.add({
          "payment_method": "BANKTF",
          "amount": _transferAmount.toInt(),
          "details": {
            "provider": "BCEL_ONE",
            "transaction_ref1": _transferRefController.text.trim(),
            "transaction_ref2": ""
          }
        });
      }

      double totalPaid = _amountReceived + _transferAmount;
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

      // Log ข้อมูลที่ส่งไป API
      log('--- 📤 SPLIT PAYMENT REQUEST ---');
      log('Payload: ${json.encode(fullPayload)}');

      Map<String, dynamic> fullResponseMap;

      // ตรวจสอบว่ามีหลายตั๋วหรือไม่
      if (widget.cart.length > 1 || ticketsPayload.length > 1) {
        // ใช้ multiple-split API สำหรับหลายตั๋ว
        log('🌐 Calling API: sellDayPassMultipleSplit (multiple tickets)...');
        fullResponseMap =
            await _visitorApiB.sellDayPassMultipleSplit(fullPayload);
      } else {
        // ใช้ single-split API สำหรับตั๋วเดียว
        log('🌐 Calling API: sellDayPassSplit (single ticket)...');
        // ปรับ payload สำหรับ single-split
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

      // Log ข้อมูลที่ได้จาก API
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
      }

      log('--- ✅ Split Payment Success ---');
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
      } else {
        // ถ้ายกเลิกจากหน้าใบเสร็จ ให้ reset transfer mode
        setState(() {
          _isTransferMode = false;
          _isProcessing = false;
        });
      }
    } catch (e) {
      log("--- ❌ Split Payment API Error ---");
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

  Future<void> _handleConfirmPayment() async {
    // ຕรวจสอบยอดเงิน
    double totalPaid =
        _isTransferMode ? (_amountReceived + _transferAmount) : _amountReceived;

    if (totalPaid < widget.totalPrice) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ຈໍານວນເງິນທີ່ໄດ້ຮັບໜ້ອຍກວ່າລາຄາປີ້'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // ຖ້າອຍູ່ໃນໂໝດໂອນ ຕ້ອງກໍານເລກ Ref
    if (_isTransferMode && _transferRefController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ກະລຸນາກໍານເລກອ້າງອີງການໂອນ'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // ໃຊ split payment API ສຳລບທກກລະນການຊຳລະ
    await _handleSplitPayment();
  }

  // Old normal payment code - not used anymore
  void _oldPaymentFlow() async {
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
            "ticket_id": allTicketIdsInCart, // 👈 ticket_id as Array
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
        

        final Map<String, dynamic> responseMap = await _visitorApi.sellDayPass(
          flatPayload,
        );
        log('--- ✅ Full API (A) Response ---: ${json.encode(responseMap)}');

        // เช็คว่ามี payments array หรือไม่
        log('🔍 Checking payments in response...');
        if (responseMap['payments'] != null) {
          log('✅ Has payments array: ${json.encode(responseMap['payments'])}');
        } else {
          log('⚠️ No payments array - will use fallback');
          log('   payment_method from root: ${responseMap['payment_method']}');
          log('   amount_paid from root: ${responseMap['amount_paid']}');
        }

        final List<dynamic>? purchasesList =
            responseMap['purchases'] as List<dynamic>?;
        if (purchasesList == null || purchasesList.isEmpty) {
          throw Exception('API (A) did not return "purchases" list.');
        }

        final Map<String, dynamic> purchaseMap = purchasesList.first;

        log('📌 About to call ApiTicketResponse.fromMap()...');
        apiResponses.add(
          ApiTicketResponse.fromMap(
            purchaseMap: purchaseMap,
            rootMap: responseMap,
            globalAdultQty: widget.globalAdultQty,
            globalChildQty: widget.globalChildQty,
          ),
        );
        log('✅ ApiTicketResponse created successfully');
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
      } else {
        // ถ้ายกเลิกจากหน้าใบเสร็จ ให้ reset state
        setState(() {
          _isProcessing = false;
        });
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
    // ຕรวจสอบเงื่อนไขการยืนยัน
    bool canConfirm;
    if (_isTransferMode) {
      // ໃນໂໝດໂອນ: ຕ້ອງກໍານເລກ Ref ແລະຍອດຄໍບ
      canConfirm = _transferRefController.text.trim().isNotEmpty &&
          (_amountReceived + _transferAmount) >= widget.totalPrice &&
          !_isProcessing;

      // Debug log - แสดงเมื่อมีการกดธนบัตร
      if (_amountReceived > 0) {
        log('💰 Transfer Mode Check: cash=$_amountReceived, transfer=$_transferAmount, total=${_amountReceived + _transferAmount}, required=${widget.totalPrice}, ref=${_transferRefController.text.length} chars, canConfirm=$canConfirm');
      }
    } else {
      // ໂໝດປກຕິ: ຕ້ອງมີເງິນຄໍບ
      canConfirm = _amountReceived >= widget.totalPrice && !_isProcessing;
    }
    return Column(
      children: [
        const SizedBox(height: 10), // เพิ่ม margin ด้านบน
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ຍອດເງິນລວມທັງໝົດ: ${currencyFormat.format(widget.totalPrice)} ກີບ',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
        ),
        const SizedBox(height: 16),
        // แสดงปุ่มธนบัตรและช่องข้อมูลการโอนด้านล่าง ถ้าอยู่ในโหมดโอน
        if (_isTransferMode)
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 24,
                  bottom: 16), // ລດ padding ດ້ານລ່າງເພື່ອໃຫ້ປຸ່ມົຂໍາບລົງໄດ້
              child: Column(
                children: [
                  _buildDenominationButtons(),
                  const SizedBox(height: 16),
                  _buildTransferSection(),
                  const SizedBox(height: 24),
                  _buildActionButtons(context, canConfirm),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        // ในโหมดปกติ แสดงแบบเดิม
        if (!_isTransferMode)
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.only(left: 8, right: 8, top: 24, bottom: 16),
              child: Column(
                children: [
                  _buildDenominationButtons(),
                  _buildSummaryInfo(),
                  const SizedBox(height: 24),
                  _buildActionButtons(context, canConfirm),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransferSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'ຂໍ້ມູນການໂອນເງິນ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // เงินสด
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ເງິນສົດ:', style: TextStyle(fontSize: 16)),
              SizedBox(
                width: 180,
                child: TextFormField(
                  controller: _amountController,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  readOnly: true, // ບໍ່ໃຫ້ແກ້ໄຂໃນໂໝດໂອນ
                  style: const TextStyle(
                    fontSize: 18,
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ยอดโอน
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ຍອດໂອນ:', style: TextStyle(fontSize: 16)),
              SizedBox(
                width: 180,
                child: TextFormField(
                  controller: _transferAmountController,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  readOnly: true, // ບໍ່ໃຫ້ແກ້ໄຂໃນໂໝດໂອນ
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // เลข Ref
          TextFormField(
            controller: _transferRefController,
            keyboardType: TextInputType.number,
            readOnly: _isProcessing,
            decoration: InputDecoration(
              labelText: 'ເລກອ້າງອີງ (Ref)',
              hintText: 'ປ້ອນເລກ Ref ການໂອນ',
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: (_transferRefController.text.trim().length < 5)
                      ? Colors.red
                      : Colors.grey,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: (_transferRefController.text.trim().length < 5)
                      ? Colors.red
                      : Colors.grey,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: (_transferRefController.text.trim().length < 5)
                      ? Colors.red
                      : Colors.blue,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
            ),
          ),
        ],
      ),
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

          // ถ้าอยู่ในโหมดโอน แสดงเฉพาะปุ่มที่มีจำนวน > 0
          if (_isTransferMode && count == 0) {
            return const SizedBox.shrink();
          }

          return GestureDetector(
            onTap: _isProcessing || _isTransferMode
                ? null
                : () => _updateFromButtons(denomination, 1),
            onLongPress: _isProcessing || _isTransferMode
                ? null
                : () => _updateFromButtons(denomination, -1),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 100,
                  height: 70,
                  decoration: BoxDecoration(
                    color:
                        _isTransferMode ? Colors.grey[200] : Colors.amber[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isTransferMode
                          ? Colors.grey[400]!
                          : Colors.amber[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      currencyFormat.format(denomination),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isTransferMode
                            ? Colors.grey[600]
                            : Colors.brown[800],
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
        // ปุ่มล้าง - แสดงเฉพาะเมื่อไม่อยู่ในโหมดโอน
        if (!_isTransferMode) ...[
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
          const SizedBox(width: 12),
        ],
        // ปุ่มโอน
        GestureDetector(
          // ปิดปุ่มถ้า: กำลัง process หรือ เงินสดเกิน/เท่ากับราคารวม
          onTap: (_isProcessing || _amountReceived >= widget.totalPrice)
              ? null
              : _toggleTransferMode,
          child: Container(
            width: 100,
            height: 70,
            decoration: BoxDecoration(
              // ถ้าปิดปุ่มให้เป็นสีเทา
              color: (_isProcessing || _amountReceived >= widget.totalPrice)
                  ? Colors.grey[300]
                  : (_isTransferMode ? Colors.blue[100] : Colors.blue[50]),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (_isProcessing || _amountReceived >= widget.totalPrice)
                    ? Colors.grey[500]!
                    : (_isTransferMode ? Colors.blue[700]! : Colors.blue),
                width: _isTransferMode ? 3 : 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: (_isProcessing || _amountReceived >= widget.totalPrice)
                      ? Colors.grey[600]
                      : (_isTransferMode ? Colors.blue[700] : Colors.blue),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  'ໂອນ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        (_isProcessing || _amountReceived >= widget.totalPrice)
                            ? Colors.grey[600]
                            : (_isTransferMode
                                ? Colors.blue[700]
                                : Colors.blue[700]),
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
    // ถ้าอยู่ในโหมดโอน ไม่ต้องแสดงส่วนนี้เลย (ย้ายไปอยู่ใน _buildTransferSection แล้ว)
    if (_isTransferMode) {
      return const SizedBox.shrink();
    }

    double totalPaid = _amountReceived + _transferAmount;
    double calculatedChange = totalPaid - widget.totalPrice;
    if (calculatedChange < 0) calculatedChange = 0;

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

          // แสดงเงินทอนเฉพาะเมื่อไม่ได้อยู่ในโหมดโอน
          if (!_isTransferMode) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ເງິນທອນ:', style: TextStyle(fontSize: 18)),
                Text(
                  '${currencyFormat.format(calculatedChange)} ກີບ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ],
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
