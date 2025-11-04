import 'dart:convert';

// Model นี้ ตรงกับ JSON ที่ API ส่งกลับมา (ตามรูป)
class ApiTicketResponse {
  final String status;
  final String message;
  final int purchaseId;
  final String visitorUid;
  final String qrCode; // "data:image/svg+xml;base64,..."

  ApiTicketResponse({
    required this.status,
    required this.message,
    required this.purchaseId,
    required this.visitorUid,
    required this.qrCode,
  });

  // Factory constructor สำหรับแปลง JSON (Map) เป็น Object
  factory ApiTicketResponse.fromMap(Map<String, dynamic> map) {
    return ApiTicketResponse(
      status: map['status'] as String,
      message: map['message'] as String,
      purchaseId: map['purchase_id'] as int,
      visitorUid: map['visitor_uid'] as String,
      qrCode: map['qr_code'] as String,
    );
  }

  factory ApiTicketResponse.fromJson(String source) =>
      ApiTicketResponse.fromMap(json.decode(source) as Map<String, dynamic>);
}
