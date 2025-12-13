// import 'dart:convert';
import 'dart:developer'; // ເພື່ອໃຊ້ log

// ======================================================
// ▼▼▼ Helper Functions ▼▼▼
// ======================================================
int _safeParseInt(dynamic value, String fieldName) {
  if (value == null) {
    return 0;
  }
  final String stringValue = value.toString().replaceAll(',', '');
  return int.tryParse(stringValue) ?? 0;
}

String _safeParseString(dynamic value, String fieldName) {
  if (value == null) {
    return '';
  }
  return value.toString();
}

bool _safeParseBool(dynamic value, String fieldName) {
  if (value == null) {
    return false;
  }
  if (value is bool) {
    return value;
  }
  return value.toString().toLowerCase() == 'true' || value.toString() == '1';
}
// ======================================================
// ▲▲▲ Helper Functions ▲▲▲
// ======================================================

class ApiTicketResponse {
  final int purchaseId;
  final String visitorUid;
  final String qrCode;

  final int amountDue;
  final int amountPaid;
  final int changeAmount;

  final List<String> rideNames;

  final int adultCount;
  final int childCount;

  // 🟢 [1] เพิ่มตัวแปรวันที่
  final String purchaseDate;

  // 🟢 [4] เพิ่มตัวแปร qrData สำหรับส่งไปพิมพ์ (Format JSON)
  final String qrData;

  ApiTicketResponse({
    required this.purchaseId,
    required this.visitorUid,
    required this.qrCode,
    required this.amountDue,
    required this.amountPaid,
    required this.changeAmount,
    required this.rideNames,
    required this.adultCount,
    required this.childCount,
    required this.purchaseDate,
    // 🟢 [5] เพิ่มใน Constructor
    required this.qrData,
  });

  factory ApiTicketResponse.fromMap({
    required Map<String, dynamic> purchaseMap,
    required Map<String, dynamic> rootMap,
    required int globalAdultQty,
    required int globalChildQty,
  }) {
    List<String> extractedRideNames = [];

    try {
      if (purchaseMap['tickets'] != null && purchaseMap['tickets'] is List) {
        var purchasedRideDataList = (purchaseMap['tickets'] as List)
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

    // --- เตรียมข้อมูล ID และ Visitor UID ก่อน ---
    int pId = _safeParseInt(purchaseMap['purchase_id'], 'purchase_id');
    String vUid = _safeParseString(purchaseMap['visitor_uid'], 'visitor_uid');

    // 🟢 [6] สร้าง qrData ตามรูปแบบ JSON ที่ต้องการ: {"purchase":857,"visitor":"..."}
    // เราสร้างขึ้นมาใหม่เลยเพื่อให้ข้อมูลตรงกับ ID และ UID ของตั๋วใบนี้แน่นอน
    String generatedQrData = '{"purchase":$pId,"visitor":"$vUid"}';

    return ApiTicketResponse(
      // --- ข้อมูลจาก purchaseMap ---
      purchaseId: pId,
      visitorUid: vUid,
      qrCode: _safeParseString(purchaseMap['qr_code'], 'qr_code'),

      // --- ข้อมูลจาก rootMap ---
      amountDue: _safeParseInt(rootMap['amount_due'], 'amount_due'),
      amountPaid: _safeParseInt(rootMap['amount_paid'], 'amount_paid'),
      changeAmount: _safeParseInt(rootMap['change_amount'], 'change_amount'),

      // [3] ดึงวันที่
      purchaseDate: _safeParseString(
        rootMap['created_at'] ?? rootMap['date'] ?? DateTime.now().toString(),
        'purchase_date',
      ),

      // --- ข้อมูลที่ Enrich ใส่ ---
      rideNames: extractedRideNames,
      adultCount: globalAdultQty,
      childCount: globalChildQty,

      // 🟢 [7] ใส่ค่า qrData ที่สร้างไว้
      qrData: generatedQrData,
    );
  }
}
