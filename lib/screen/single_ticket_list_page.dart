import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../models/cart_item.dart';
import '../widgets/ticket_card.dart';
import '../services/ticket_api.dart';

class SingleTicketListPage extends StatefulWidget {
  final Ticket? selectedTicket;
  final List<CartItem> cart; // Receive cart to check status
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
          return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const Center(child: Text('No ticket data found'));

        final List<Ticket> allTickets = snapshot.data!;
        final List<Ticket> ticketList =
            allTickets.where((ticket) => ticket.type == 'single').toList();

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.6,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: ticketList.length,
          itemBuilder: (context, index) {
            final ticket = ticketList[index];

            // 1. Check if already in cart
            final bool alreadyInCart = widget.cart.any(
              (item) => item.ticket.ticketId == ticket.ticketId,
            );
            // 2. Check if currently selected
            final bool isSelected =
                widget.selectedTicket?.ticketId == ticket.ticketId;

            // 3. Adjust UI: if already in cart, dim it and disable tap
            return Opacity(
              opacity: alreadyInCart ? 0.5 : 1.0,
              child: TicketCard(
                ticket: ticket,
                isSelected: isSelected,
                onTap: alreadyInCart
                    ? null // Cannot tap if already selected
                    : () => widget.onTicketSelected(ticket),
              ),
            );
          },
        );
      },
    );
  }
}
