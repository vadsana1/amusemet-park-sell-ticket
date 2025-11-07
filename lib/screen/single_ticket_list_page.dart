import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../widgets/ticket_card.dart';
import '../services/ticket_api.dart'; // <-- [แก้ไข] เพิ่มบรรทัดนี้

class SingleTicketListPage extends StatefulWidget {
 // [แก้ไข] 1. รับ State และ Callback แบบง่าย
 final Ticket? selectedTicket;
 final void Function(Ticket ticket) onTicketSelected;

 const SingleTicketListPage({
  super.key,
  required this.onTicketSelected,
  this.selectedTicket,
 });

 @override
 State<SingleTicketListPage> createState() => _SingleTicketListPageState();
}

class _SingleTicketListPageState extends State<SingleTicketListPage> {
  // ตอนนี้ Flutter รู้จัก 'TicketApi' แล้ว
 final TicketApi _ticketApi = TicketApi();
 late Future<List<Ticket>> _futureTickets;

 @override
 void initState() {
  super.initState();
  _futureTickets = _ticketApi.fetchTickets();
 }

 @override
 Widget build(BuildContext context) {
  return FutureBuilder<List<Ticket>>(
   future: _futureTickets,
   builder: (context, snapshot) {
    // --- ส่วนจัดการสถานะ (Loading, Error) ---
    if (snapshot.connectionState == ConnectionState.waiting) {
     return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
     return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
     return const Center(child: Text('ไม่พบข้อมูลตั๋ว'));
    }

    // --- เมื่อสำเร็จ (Success) ---
    final List<Ticket> allTickets = snapshot.data!; 
    final List<Ticket> ticketList = allTickets
      .where((ticket) => ticket.type == 'single') 
      .toList();
        if (ticketList.isEmpty) {
          return const Center(child: Text('ไม่พบข้อมูลตั๋ว (ประเภท single)'));
        }

    // [แก้ไข] 3. ลบ Column และ ToggleButtons ทิ้ง
    // (แสดง GridView โดยตรง)
    return GridView.builder(
     padding: const EdgeInsets.all(16.0),
     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3, 
      childAspectRatio: 2.0, 
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
     ),
     itemCount: ticketList.length,
     itemBuilder: (context, index) {
      final ticket = ticketList[index];

      // [แก้ไข] 4. ตรวจสอบการเลือก (แบบง่าย)
      final bool isSelected =
        widget.selectedTicket?.ticketId == ticket.ticketId;

      // 5. สร้าง TicketCard
      return TicketCard(
       ticket: ticket,
       isSelected: isSelected, 
       // [แก้ไข] 6. Logic การ OnTap (ง่ายขึ้น)
       onTap: () {
        // เรียก Callback ไปที่ HomePage
        widget.onTicketSelected(ticket);
       },
      );
     },
    );
   },
  );
 }
}