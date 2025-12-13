import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../models/cart_item.dart';
import '../widgets/ticket_card.dart';
import '../services/ticket_api.dart';

class SingleTicketListPage extends StatefulWidget {
  final Ticket? selectedTicket;
  final List<CartItem> cart; // รับตะกร้าเข้ามาเพื่อเช็คสถานะ
  final void Function(Ticket ticket) onTicketSelected;

  const SingleTicketListPage({
    super.key,
    required this.onTicketSelected,
    this.selectedTicket,
    required this.cart,
  });

  @override
  State<SingleTicketListPage> createState() => _SingleTicketListPageState();
}

class _SingleTicketListPageState extends State<SingleTicketListPage> {
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
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const Center(child: Text('ไม่พบข้อมูลตั๋ว'));

        final List<Ticket> allTickets = snapshot.data!;
        final List<Ticket> ticketList = allTickets
            .where((ticket) => ticket.type == 'single')
            .toList();

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

            // 1. เช็คว่าอยู่ในตะกร้าไหม
            final bool alreadyInCart = widget.cart.any(
              (item) => item.ticket.ticketId == ticket.ticketId,
            );
            // 2. เช็คว่าเป็นตัวที่เลือกอยู่ไหม
            final bool isSelected =
                widget.selectedTicket?.ticketId == ticket.ticketId;

            // 3. ปรับ UI: ถ้าอยู่ในตะกร้าแล้ว ให้จางลง และกดไม่ได้
            return Opacity(
              opacity: alreadyInCart ? 0.5 : 1.0,
              child: TicketCard(
                ticket: ticket,
                isSelected: isSelected,
                onTap: alreadyInCart
                    ? null // กดไม่ได้ถ้าเลือกไปแล้ว
                    : () => widget.onTicketSelected(ticket),
              ),
            );
          },
        );
      },
    );
  }
}
