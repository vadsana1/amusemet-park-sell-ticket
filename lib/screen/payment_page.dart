import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/payment_method.dart';
import './payment_cash_view.dart';
import './payment_qr_view.dart';
import '../widgets/visitor_form_widget.dart'; // 👈 1. Import Widget ໃໝ່

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

  // 🚀 NEW HELPER: Logic ເລືອກ CASH ເປັນອັນທໍາອິດ
  void _selectInitialPaymentMethod(List<PaymentMethod> methods) {
    if (methods.isNotEmpty) {
      // 1. ພະຍາຍາມຊອກຫາ CASH
      final cashMethod = methods.firstWhere(
        (method) => method.code == 'CASH',
        orElse: () => methods.first, // 2. ຖ້າບໍ່ພົບ, ໃຫ້ເລືອກອັນທໍາອິດ
      );
      _selectedPaymentCode = cashMethod.code;
    }
  }

 @override
 void initState() {
  super.initState();
  // 🚀 FIX 1: ໃຊ້ Helper ເພື່ອເລືອກ CASH ກ່ອນ
  _selectInitialPaymentMethod(widget.paymentMethods);
  
  _fullNameController = TextEditingController(text: 'customer');
  _phoneController = TextEditingController(text: '02012345678');
 }

 // ⭐️⭐️⭐️ ADD THIS FUNCTION ⭐️⭐️⭐️
 @override
 void didUpdateWidget(covariant PaymentPage oldWidget) {
  super.didUpdateWidget(oldWidget);

  // ກວດສອບວ່າ: paymentMethods ຫາກໍໂຫຼດມາສຳເລັດ
  if (widget.paymentMethods.isNotEmpty &&
    oldWidget.paymentMethods.isEmpty &&
    _selectedPaymentCode == null) {
   // ສັ່ງ setState ເພື່ອເລືອກ payment method ຕາມເງື່ອນໄຂ (CASH ກ່ອນ)
   setState(() {
        // 🚀 FIX 2: ໃຊ້ Helper ເພື່ອເລືອກ CASH ກ່ອນເມື່ອ data ມາ
    _selectInitialPaymentMethod(widget.paymentMethods);
   });
  }
 }
 // ⭐️⭐️⭐️ END OF ADDED FUNCTION ⭐️⭐️⭐️

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
       '${item.totalPrice.toStringAsFixed(0)} ກີບ',
       textAlign: TextAlign.right,
      ),
     ),
    ],
   ),
  );
 }

 // --- Widget: ສ່ວນຊຳລະເງິນ (ດ້ານຂວາ) ---
 Widget _buildPaymentSection() {
  // ⭐️ ບ່ອນນີ້ຄືຈຸດທີ່ສະແດງໂຕໝຸນ
  if (_selectedPaymentCode == null) {
   // ກວດສອບເພີ່ມ: ຖ້າ _selectedPaymentCode ເປັນ null
   // ແລະ paymentMethods ກໍຍັງບໍ່ມາ (ຍັງວ່າງ) -> ສະແດງໂຕໝຸນ
   if (widget.paymentMethods.isEmpty) {
    return const Center(child: CircularProgressIndicator());
   }
   // ແຕ່ຖ້າ paymentMethods ມ ແລ້ວ ແຕ່ code ຍັງ null (ເຊັ່ນ error ບາງຢ່າງ)
   // ໃຫ້ສະແດງ error ແທນທີ່ຈະໝຸນຄ້າງ
   return const Center(
    child: Text('Error: ບໍ່ສາມາດເລືອກຊ່ອງທາງຊຳລະເງິນໄດ້'),
   );
  }

  return Padding(
   padding: const EdgeInsets.all(24.0),
   // 🎯 [FIX 3] ປ່ຽນຈາກ Form ເປັນ Column
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
     // 1. HIDDEN INFO AND PAYMENT HEADER
     Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       // 🎯 [FIX 4] ເອີ້ນໃຊ້ VisitorFormWidget ທີ່ແຍກອອກໄປ
       Offstage(
        child: VisitorFormWidget(
         formKey: _formKey, // 👈 ສົ່ງ Key
         fullNameController: _fullNameController, // 👈 ສົ່ງ Controller
         phoneController: _phoneController, // 👈 ສົ່ງ Controller
         initialGender: _selectedGender, // 👈 ສົ່ງຄ່າເລີ່ມຕົ້ນ
         onGenderChanged: (newValue) {
          // 👈 ຮັບຄ່າ Gender ທີ່ປ່ຽນກັບມາ
          setState(() {
           _selectedGender = newValue;
          });
         },
        ),
       ),

       // PAYMENT HEADER (ຄືເກົ່າ)
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

     // 2. PAYMENT VIEWS (ຄືເກົ່າ)
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
         ),
     ),
    ],
   ),
  );
 }


 Widget _buildPaymentTabs() {
  if (widget.paymentMethods.isEmpty) {
   // ຖ້າ paymentMethods ເປັນ null ຫຼື ວ່າງ, ຈະບໍ່ສະແດງຫຍັງເລີຍ
   // (ເພາະ _buildPaymentSection ຈະສະແດງໂຕໝຸນແທນ)
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