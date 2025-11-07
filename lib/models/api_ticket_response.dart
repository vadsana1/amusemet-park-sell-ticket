import 'dart:convert';
import 'dart:developer'; // เพื่อใช้ log

// ======================================================
// ▼▼▼ Helper Functions (อยู่บนสุด) ▼▼▼
// ======================================================
int _safeParseInt(dynamic value, String fieldName) {
  if (value == null) {
    log('Warning: API returned null for "$fieldName". Using 0.');
    return 0;
  }
  return int.tryParse(value.toString()) ?? 0;
}

String _safeParseString(dynamic value, String fieldName) {
  if (value == null) {
    log('Warning: API returned null for "$fieldName". Using empty string.');
    return '';
  }
  return value.toString();
}

bool _safeParseBool(dynamic value, String fieldName) {
  if (value == null) {
    log('Warning: API returned null for "$fieldName". Using false.');
    return false;
  }
  if (value is bool) {
    return value;
  }
  return value.toString().toLowerCase() == 'true' || value.toString() == '1';
}
// ======================================================
// ▲▲▲ Helper Functions (สิ้นสุด) ▲▲▲
// ======================================================

class ApiTicketResponse {
  final int purchaseId;
  final String visitorUid;
  final String qrCode;

  // ⭐️ ADD 1: เพิ่ม field สำหรับยอดเงินที่ต้องจ่ายและยอดที่รับมา
  final int amountDue;
  final int amountPaid;
  final int changeAmount; // อันนี้มีอยู่แล้ว

  final List<String> rideNames;

  final int adultCount;
  final int childCount;

  ApiTicketResponse({
    required this.purchaseId,
    required this.visitorUid,
    required this.qrCode,
    // ⭐️ ADD 2: เพิ่ม required ใน constructor
    required this.amountDue,
    required this.amountPaid,
    required this.changeAmount,
    required this.rideNames,
    required this.adultCount,
    required this.childCount,
  });

  factory ApiTicketResponse.fromMap(
    Map<String, dynamic> map, {
    required int globalAdultQty,
    required int globalChildQty,
  }) {
    List<String> extractedRideNames = [];

    try {
      if (map['tickets'] != null && map['tickets'] is List) {
        var purchasedRideDataList = (map['tickets'] as List)
            .where(
              (ride) =>
                  ride is Map &&
                  _safeParseBool(ride['buy_ride'], 'buy_ride') == true,
            )
            .toList();

        for (var rideData in purchasedRideDataList) {
          final rideMap = rideData as Map<String, dynamic>;

          String rideName = _safeParseString(rideMap['ride_name'], 'ride_name');

          if (rideName.isNotEmpty) {
            extractedRideNames.add(rideName);
          }
        }
      }
    } catch (e) {
      log('Error parsing nested "tickets" array: $e');
    }

    return ApiTicketResponse(
      // --- ข้อมูลจาก Top-Level ---
      purchaseId: _safeParseInt(map['purchase_id'], 'purchase_id'),
      visitorUid: _safeParseString(map['visitor_uid'], 'visitor_uid'),
      qrCode: _safeParseString(map['qr_code'], 'qr_code'),

      // ⭐️ ADD 3: ดึงค่าจาก map โดยใช้ helper ที่ปลอดภัย
      amountDue: _safeParseInt(map['amount_due'], 'amount_due'),
      amountPaid: _safeParseInt(map['amount_paid'], 'amount_paid'),
      changeAmount: _safeParseInt(map['change_amount'], 'change_amount'),

      // --- ข้อมูลใหม่ที่เรา Enrich ใส่ ---
      rideNames: extractedRideNames,
      adultCount: globalAdultQty,
      childCount: globalChildQty,
    );
  }

  factory ApiTicketResponse.fromJson(
    String source, {
    required int globalAdultQty,
    required int globalChildQty,
  }) => ApiTicketResponse.fromMap(
    json.decode(source) as Map<String, dynamic>,
    globalAdultQty: globalAdultQty,
    globalChildQty: globalChildQty,
  );
}
