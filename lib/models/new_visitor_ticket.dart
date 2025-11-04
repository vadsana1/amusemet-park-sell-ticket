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

// --- 2. Model TicketDetail (ຄືເກົ່າ) ---
class TicketDetail {
 final int ticketId;
 final String visitorType;
 TicketDetail({required this.ticketId, required this.visitorType});
 Map<String, dynamic> toMap() {
  return {'ticket_id': ticketId, 'visitor_type': visitorType};
 }
}

// --- 3. Model ຫຼັກ NewVisitorTicket (ແກ້ໄຂ) ---
class NewVisitorTicket {
 final String visitorUid;
 final String fullName;
 final String phone;
 final String gender;
  // [ແກ້ໄຂ 1] ລຶບ visitorType ລະດັບນອກອອກ
 // final String visitorType; 

 final List<TicketDetail> tickets;
 final String paymentMethod;
 final int amountDue;
 final int amountPaid;
 final int changeAmount;
  // [ແກ້ໄຂ 2] ປ່ຽນຊື່ຕົວແປ (variable) ໃຫ້ກົງກັບ API
 final List<CashDetail>? paymentTransactions; 

 NewVisitorTicket({
  required this.visitorUid,
  required this.fullName,
  required this.phone,
  required this.gender,
    // [ແກ້ໄຂ 3] ລຶບ visitorType ອອກຈາກ constructor
  // required this.visitorType, 
  required this.tickets,
  required this.paymentMethod,
  required this.amountDue,
  required this.amountPaid,
  required this.changeAmount, 
    // [ແກ້ໄຂ 4] ປ່ຽນຊື່ໃນ constructor
  this.paymentTransactions, 
 });

 // [ແກ້ໄຂ 5] (ສຳຄັນທີ່ສຸດ) ປ່ຽນ Key ໃນ toMap()
 Map<String, dynamic> toMap() {
  final map = {
   'visitor_uid': visitorUid,
   'full_name': fullName,
   'phone': phone,
   'gender': gender,
      // 'visitor_type': visitorType, // <-- ລຶບແຖວນີ້
   'tickets': tickets.map((t) => t.toMap()).toList(),
   'payment_method': paymentMethod,
   'amount_due': amountDue,
   'amount_paid': amountPaid,
   'change_amount': changeAmount, 
  };

    // ປ່ຽນ 'cash_details' ເປັນ 'payment_transactions'
  if (paymentTransactions != null && paymentTransactions!.isNotEmpty) {
   map['payment_transactions'] = paymentTransactions!.map((c) => c.toMap()).toList();
  }

  return map;
 }

 String toJson() => json.encode(toMap());
}