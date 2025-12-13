class Ticket {
  final String ticketName;
  final double priceAdult;
  final double priceChild;
  final String type;
  final int ticketId;
  final String? imageUrl; 

  const Ticket({
    required this.ticketName,
    required this.priceAdult,
    required this.priceChild,
    required this.type,
    required this.ticketId,
    this.imageUrl, 
  });

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      ticketName: map['ticket_name'] as String,
      priceAdult: double.parse(map['price_adult'].toString()),
      priceChild: double.parse(map['price_child'].toString()),
      type: map['type'] as String,
      ticketId: map['ticket_id'] as int,
 
      imageUrl: map['image_url'] as String?,
    );
  }
}
