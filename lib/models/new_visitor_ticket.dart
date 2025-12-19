import 'dart:convert';

// --- 1. Model CashDetail (same as before) ---
class CashDetail {
  final int denomination;
  final int quantity;

  CashDetail({required this.denomination, required this.quantity});

  Map<String, dynamic> toMap() {
    return {'denomination': denomination, 'quantity': quantity};
  }
}

// --- 2. Model TicketDetail (Modified: Added gender) ---
class TicketDetail {
  final int ticketId;
  final String visitorType;
  final String gender; // <-- ✅ Added gender field

  TicketDetail({
    required this.ticketId,
    required this.visitorType,
    required this.gender, // <-- ✅ Added to constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'ticket_id': ticketId,
      'visitor_type': visitorType,
      'gender': gender, // <-- ✅ Added to toMap
    };
  }
}

// --- 3. Main Model NewVisitorTicket (Updated to match API Payload) ---
class NewVisitorTicket {
  final String visitorUid;
  final String fullName;
  final String phone;
  final String gender;

  final List<TicketDetail> tickets;
  final String paymentMethod;
  final int amountDue;
  final int amountPaid;
  final int changeAmount;
  final List<CashDetail>? paymentTransactions; // Renamed to match API

  NewVisitorTicket({
    required this.visitorUid,
    required this.fullName,
    required this.phone,
    required this.gender,
    required this.tickets,
    required this.paymentMethod,
    required this.amountDue,
    required this.amountPaid,
    required this.changeAmount,
    this.paymentTransactions,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'visitor_uid': visitorUid,
      'full_name': fullName,
      'phone': phone,
      'gender': gender,
      'tickets': tickets.map((t) => t.toMap()).toList(),
      'payment_method': paymentMethod,
      'amount_due': amountDue,
      'amount_paid': amountPaid,
      'change_amount': changeAmount,
    };

    // Changed 'cash_details' to 'payment_transactions'
    if (paymentTransactions != null && paymentTransactions!.isNotEmpty) {
      map['payment_transactions'] =
          paymentTransactions!.map((c) => c.toMap()).toList();
    }

    return map;
  }

  String toJson() => json.encode(toMap());
}
