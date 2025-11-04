import 'ticket.dart';

// Model for storing items in the cart
class CartItem {
  final Ticket ticket; // The product data (comes from API)
  int quantityAdult; // The selected quantity (state)
  int quantityChild; // The selected quantity (state)

  CartItem({
    required this.ticket,
    this.quantityAdult = 0,
    this.quantityChild = 0,
  });

  // --- CALCULATION PART 1 ---
  // Calculates the total price for THIS item row
  // It "pulls" the price from the 'ticket' model
  double get totalPrice {
    return (ticket.priceAdult * quantityAdult) +
        (ticket.priceChild * quantityChild);
  }

  // Helper for total quantity in this row
  int get totalQuantity {
    return quantityAdult + quantityChild;
  }
}
