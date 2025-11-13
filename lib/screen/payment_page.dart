import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cart_item.dart';
import '../models/payment_method.dart';
import './payment_cash_view.dart';
import './payment_qr_view.dart';
import '../widgets/visitor_form_widget.dart';

class PaymentPage extends StatefulWidget {
  final List<CartItem> cart;
  final double totalPrice;
  final List<PaymentMethod> paymentMethods;
  final int adultQty;
  final int childQty;

  const PaymentPage({
    super.key,
    required this.cart,
    required this.totalPrice,
    required this.paymentMethods,
    required this.adultQty,
    required this.childQty,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? _selectedPaymentCode;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  String _selectedGender = 'male';
  String _selectedVisitorType = 'adult'; // 🎯 [ແກ້ໄຂ] ເພີ່ມ State ນີ້
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");

  void _selectInitialPaymentMethod(List<PaymentMethod> methods) {
    if (methods.isNotEmpty) {
      final cashMethod = methods.firstWhere(
        (method) => method.code == 'CASH',
        orElse: () => methods.first,
      );
      _selectedPaymentCode = cashMethod.code;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectInitialPaymentMethod(widget.paymentMethods);

    _fullNameController = TextEditingController(text: 'customer');
    _phoneController = TextEditingController(text: '02012345678');
  }

  @override
  void didUpdateWidget(covariant PaymentPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.paymentMethods.isNotEmpty &&
        oldWidget.paymentMethods.isEmpty &&
        _selectedPaymentCode == null) {
      setState(() {
        _selectInitialPaymentMethod(widget.paymentMethods);
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ສະຫຼຸບລາຍການ ແລະ ຊຳລະເງິນ'),
        backgroundColor: const Color(0xFF1A9A8B),
      ),
      body: Row(
        children: [
          Expanded(flex: 6, child: _buildSummarySection()),
          Container(
            width: 450,
            color: const Color(0xFFEAEAEA),
            child: _buildPaymentSection(),
          ),
        ],
      ),
    );
  }

  // --- Widget: ສ່ວນສະຫຼຸບລາຍການ (ດ້ານซ้าย) ---
  Widget _buildSummarySection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ສະຫຼຸບລາຍການ',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSummaryHeader(),
          const Divider(height: 1, color: Colors.grey),
          Expanded(
            child: ListView.builder(
              itemCount: widget.cart.length,
              itemBuilder: (context, index) {
                return _buildSummaryRow(widget.cart[index], index);
              },
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Container(
            color: const Color(0xFFD6EBE9),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ລາຄາທັງໝົດ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_currencyFormat.format(widget.totalPrice)} ກີບ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A9A8B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('ລ/ດ', style: boldStyle)),
          Expanded(flex: 4, child: Text('ຊື່', style: boldStyle)),
          Expanded(
            flex: 2,
            child: Text(
              'ຜູ້ໃຫຍ່',
              style: boldStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ເດັກນ້ອຍ',
              style: boldStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text('ລາຄາ', style: boldStyle, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(CartItem item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text((index + 1).toString())),
          Expanded(flex: 4, child: Text(item.ticket.ticketName)),
          Expanded(
            flex: 2,
            child: Text(
              item.quantityAdult.toString(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.quantityChild.toString(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${_currencyFormat.format(item.totalPrice)} ກີບ',
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    if (_selectedPaymentCode == null) {
      if (widget.paymentMethods.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Center(
        child: Text('Error: ບໍ່ສາມາດເລືອກຊ່ອງທາງຊຳລະເງິນໄດ້'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Offstage(
                child: VisitorFormWidget(
                  formKey: _formKey,
                  fullNameController: _fullNameController,
                  phoneController: _phoneController,
                  initialGender: _selectedGender,
                  onGenderChanged: (newValue) {
                    setState(() {
                      _selectedGender = newValue;
                    });
                  },
                  initialVisitorType: _selectedVisitorType,
                  onVisitorTypeChanged: (newType) {
                    setState(() {
                      _selectedVisitorType = newType;
                    });
                  },
                ),
              ),
              Text(
                'ຊຳລະເງິນ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentTabs(),
              const SizedBox(height: 24),
            ],
          ),
          Expanded(
            child: _selectedPaymentCode == 'CASH'
                ? PaymentCashView(
                    totalPrice: widget.totalPrice,
                    cart: widget.cart,
                    paymentMethodCode: _selectedPaymentCode!,
                    visitorFullName: _fullNameController.text,
                    visitorPhone: _phoneController.text,
                    visitorGender: _selectedGender,
                    globalAdultQty: widget.adultQty,
                    globalChildQty: widget.childQty,
                    visitorType:
                        _selectedVisitorType,
                  )
                : PaymentQrView(
                    totalPrice: widget.totalPrice,
                    cart: widget.cart,
                    paymentMethodCode: _selectedPaymentCode!,
                    visitorFullName: _fullNameController.text,
                    visitorPhone: _phoneController.text,
                    visitorGender: _selectedGender,
                    globalAdultQty: widget.adultQty,
                    globalChildQty: widget.childQty,
                    visitorType:
                        _selectedVisitorType, 
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTabs() {
    if (widget.paymentMethods.isEmpty) {
      return const SizedBox.shrink();
    }

    final isSelected = widget.paymentMethods.map((method) {
      return method.code == _selectedPaymentCode;
    }).toList();

    final children = widget.paymentMethods.map((method) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(method.name),
      );
    }).toList();

    return Center(
      child: ToggleButtons(
        isSelected: isSelected,
        onPressed: (index) {
          setState(() {
            _selectedPaymentCode = widget.paymentMethods[index].code;
          });
        },
        borderRadius: BorderRadius.circular(8),
        selectedBorderColor: const Color(0xFF1A9A8B),
        selectedColor: Colors.white,
        fillColor: const Color(0xFF1A9A8B),
        children: children,
      ),
    );
  }
}
