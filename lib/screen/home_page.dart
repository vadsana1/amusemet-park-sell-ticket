import 'package:flutter/material.dart';
import '../models/ticket.dart'; 
import '../models/payment_method.dart'; 
import '../widgets/side_menu.dart';
import '../widgets/home_page_header.dart';

import 'single_ticket_list_page.dart'; 
import 'single_ticket_page.dart'; 
import 'package_ticket_page.dart'; 
import 'user_page.dart';

class HomePage extends StatefulWidget {
 const HomePage({super.key});

 @override
 State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
 int _selectedIndex = 0; 

 // --- [แก้ไข] 1. State ใหม่: ความจริงหนึ่งเดียว ---
 List<Ticket> _selectedTickets = [];

 // State สำหรับ Payment (ยังต้องใช้)
 List<PaymentMethod> _paymentMethods = [];
 bool _isLoadingMethods = true;
 // ---

 @override
 void initState() {
  super.initState();
  _loadPaymentMethods(); 
 }

 // (ฟังก์ชันโหลด Payment Methods จำลอง - เหมือนเดิม)
 Future<void> _loadPaymentMethods() async {
  setState(() => _isLoadingMethods = true);
  await Future.delayed(const Duration(milliseconds: 500)); 
  final dummyData = [
   { 'id': 1, 'code': 'CASH', 'name': 'ເງິນສົດ', 'is_active': true, 'created_at': DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String(), 'config': null },
   { 'id': 2, 'code': 'QR', 'name': 'QR', 'is_active': true, 'created_at': DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String(), 'config': null }
  ];
  setState(() {
   _paymentMethods = dummyData.map((map) => PaymentMethod.fromMap(map)).toList();
   _isLoadingMethods = false;
  });
 }

 // Callback เมนูซ้าย
 void _onMenuItemTapped(int index) {
  setState(() {
   _selectedIndex = index;
   _selectedTickets = []; // [แก้ไข] ล้างการเลือก เมื่อเปลี่ยนเมนู
  });
 }

 // --- [แก้ไข] 2. Callback ใหม่: "กดตั๋ว" ---
  // (Logic ใหม่: กด 1 ครั้ง = ติ๊ก/เอาติ๊กออก)
 void _onTicketTapped(Ticket ticket) {
  setState(() {
   final isSelected = _selectedTickets.any((t) => t.ticketId == ticket.ticketId);

   if (isSelected) {
    // ถ้าเลือกอยู่แล้ว -> เอาออก
    _selectedTickets.removeWhere((t) => t.ticketId == ticket.ticketId);
   } else {
    // ถ้ายังไม่เลือก -> เพิ่ม
    _selectedTickets.add(ticket);
   }
  });
 }
 // --- [สิ้นสุดการแก้ไข] ---

 // ฟังก์ชันสร้างเนื้อหา
 Widget _buildCurrentPage() {
    if (_isLoadingMethods) {
      return const Center(child: CircularProgressIndicator());
    }

  switch (_selectedIndex) {
   case 0:
    return Row(
     children: [
      // [แก้ไข] 3. ส่ง State และ Callback ใหม่
      Expanded(
       flex: 3,
       child: SingleTicketListPage(
        onTicketTapped: _onTicketTapped, // Callback ใหม่
        selectedTickets: _selectedTickets, // List ใหม่
       ),
      ),

      // [แก้ไข] 4. ส่ง State ใหม่
      SingleTicketPage(
       selectedTickets: _selectedTickets, // List ใหม่
       paymentMethods: _paymentMethods,
      ),
     ],
    );

   // ... (case 1, 2 ... เหมือนเดิม)
   case 1:
    return const PackageTicketPage();
   case 2:
    return const UserPage();
   default:
    return const Center(child: Text("Page not found"));
  }
 }

 @override
 Widget build(BuildContext context) {
  return Scaffold(
   backgroundColor: Colors.white, 
   body: SafeArea(
    child: Column(
     children: [
      HomePageHeader(),
      Expanded(
       child: Row(
        children: [
         SideMenu(
          selectedIndex: _selectedIndex,
          onMenuItemTapped: _onMenuItemTapped,
         ),
         Expanded(child: _buildCurrentPage()),
        ],
       ),
      ),
     ],
    ),
   ),
  );
 }
}