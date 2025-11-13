import 'dart:convert';

// --- 1. Model CashDetail (ຄືເກົ່າ) ---
class CashDetail {
  final int denomination;
  final int quantity;

  CashDetail({required this.denomination, required this.quantity});

  Map<String, dynamic> toMap() {
    return {'denomination': denomination, 'quantity': quantity};
  }
}

// --- 2. Model TicketDetail (ແກ້ໄຂ: ເພີ່ມ gender) ---
class TicketDetail {
  final int ticketId;
  final String visitorType;
  final String gender; // <-- ✅ ເພີ່ມ gender ເຂົ້າມາ

  TicketDetail({
    required this.ticketId,
    required this.visitorType,
    required this.gender, // <-- ✅ ເພີ່ມໃນ constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'ticket_id': ticketId,
      'visitor_type': visitorType,
      'gender': gender, // <-- ✅ ເພີ່ມໃນ toMap
    };
  }
}

// --- 3. Model ຫຼັກ NewVisitorTicket (ປັບປຸງຕາມ Payload ຂອງ API) ---
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
  final List<CashDetail>? paymentTransactions; // ປ່ຽນຊື່ຕາມ API

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

  // (ສຳຄັນທີ່ສຸດ) toMap() ນີ້ໃຊ້ໄດ້ກັບ API ເສັ້ນດຽວ (sellDayPass)
  // ແຕ່ສຳລັບເສັ້ນ Multiple (sellDayPassMultiple) ທ່ານໄດ້ແກ້ໄຂແລ້ວໃນ PaymentCashView.dart
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

    // ປ່ຽນ 'cash_details' ເປັນ 'payment_transactions'
    if (paymentTransactions != null && paymentTransactions!.isNotEmpty) {
      map['payment_transactions'] = paymentTransactions!
          .map((c) => c.toMap())
          .toList();
    }

    return map;
  }

  String toJson() => json.encode(toMap());
}
