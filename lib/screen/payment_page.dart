import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/payment_method.dart'; 
import './payment_cash_view.dart';
import './payment_qr_view.dart';

class PaymentPage extends StatefulWidget {
 final List<CartItem> cart;
 final double totalPrice;
 final List<PaymentMethod> paymentMethods; 

 const PaymentPage({
    super.key, 
    required this.cart, 
    required this.totalPrice,
    required this.paymentMethods, 
  });

 @override
 State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
 String? _selectedPaymentCode;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  
  // [ແກ້ໄຂ] 1. ປ່ຽນຄ່າ Gender ເປັນຄຳເຕັມ (ຕາມ JSON ຕົວຢ່າງ)
  String _selectedGender = 'male'; 
  // [ແກ້ໄຂ] 2. ລຶບ VisitorType State (ເພາະ API ບໍ່ໄດ້ໃຊ້)
  // String _selectedVisitorType = 'l'; 

  @override
  void initState() {
    super.initState();
    if (widget.paymentMethods.isNotEmpty) {
      _selectedPaymentCode = widget.paymentMethods.first.code;
    }
    // ຕັ້ງຄ່າເລີ່ມຕົ້ນ
    _fullNameController = TextEditingController(text: 'customer');
    _phoneController = TextEditingController(text: '02012345678');
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
     Expanded(
      flex: 6,
      child: _buildSummarySection(), 
     ),
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
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
         '${widget.totalPrice.toStringAsFixed(0)} ກີບ',
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
     Expanded( flex: 2, child: Text( 'ຜູ້ໃຫຍ່', style: boldStyle, textAlign: TextAlign.center, ),), 
     Expanded( flex: 2, child: Text( 'ເດັກນ້ອຍ', style: boldStyle, textAlign: TextAlign.center, ),), 
     Expanded( flex: 3, child: Text('ລາຄາ', style: boldStyle, textAlign: TextAlign.right),), 
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
     Expanded( flex: 2, child: Text( item.quantityAdult.toString(), textAlign: TextAlign.center, ),),
     Expanded( flex: 2, child: Text( item.quantityChild.toString(), textAlign: TextAlign.center, ),),
     Expanded( flex: 3, child: Text( '${item.totalPrice.toStringAsFixed(0)} ກີບ', textAlign: TextAlign.right, ),),
    ],
   ),
  );
 }
  // --- [ຈົບສ່ວນໂຄ້ດເກົ່າ] ---

 Widget _buildPaymentSection() {
    if (_selectedPaymentCode == null) {
      return const Center(child: CircularProgressIndicator());
    }

  return Padding(
   padding: const EdgeInsets.all(24.0),
   child: Form( 
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ຂໍ້ມູນຜູ້ຊື້', // 'ข้อมูลผู้ซื้อ'
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildVisitorForm(),
                  const Divider(height: 32, thickness: 1),
                  Text( 
                    'ຊຳລະເງິນ', 
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentTabs(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // [ແກ້ໄຂ 3] ລຶບ visitorType ອອກຈາກການສົ່ງ
          Expanded(
      child: _selectedPaymentCode == 'CASH'
        ? PaymentCashView(
                        totalPrice: widget.totalPrice, 
                        cart: widget.cart,
                        paymentMethodCode: _selectedPaymentCode!,
                        visitorFullName: _fullNameController.text,
                        visitorPhone: _phoneController.text,
                        visitorGender: _selectedGender,
                        // visitorType: _selectedVisitorType, // <-- ລຶບອອກ
                    )
        : PaymentQrView(
                        totalPrice: widget.totalPrice,
                        cart: widget.cart,
                        paymentMethodCode: _selectedPaymentCode!,
                        visitorFullName: _fullNameController.text,
                        visitorPhone: _phoneController.text,
                        visitorGender: _selectedGender,
                        // visitorType: _selectedVisitorType, // <-- ລຶບອອກ
                    ),
     ),
        ],
   ),
    ),
  );
 }

  // [ແກ້ໄຂ 4] Widget ສຳລັບຟອມກອກຂໍ້ມູນ
  Widget _buildVisitorForm() {
    return Column(
      children: [
        // --- Full Name ---
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'ຊື່ເຕັມ (ชื่อเต็ม)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) { return 'ກະລຸນາປ້ອນຊື່'; }
            return null;
          },
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        
        // --- Phone ---
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'ເບີໂທ (เบอร์โทร)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) { return 'ກະລຸນາປ້ອນເບີໂທ'; }
            return null;
          },
          onChanged: (value) {
            setState(() {}); 
          },
        ),
        const SizedBox(height: 16),

        // --- [ແກ້ໄຂ 5] Gender (ໃຊ້ 'male' / 'female') ---
        Row(
          children: [
            const Text('ເພດ (เพศ):', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Radio<String>(
              value: 'male', // <-- ປ່ຽນເປັນ 'male'
              groupValue: _selectedGender,
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            const Text('ຊາຍ (ชาย)'),
            Radio<String>(
              value: 'female', // <-- ປ່ຽນເປັນ 'female'
              groupValue: _selectedGender,
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            const Text('ຍິງ (หญิง)'),
          ],
        ),

        // --- [ແກ້ໄຂ 6] ລຶບ Visitor Type (Local/Foreigner) ອອກ ---
        // Row( ... ), // <-- ລຶບ Row ນີ້ອອກທັງໝົດ
      ],
    );
  }

  // (Helper) ປຸ່ມ TABS (ຄືເກົ່າ)
 Widget _buildPaymentTabs() {
    if (widget.paymentMethods.isEmpty) {
      return const Center(child: Text('ບໍ່ມີຊ່ອງທາງຊຳລະເງິນ'));
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