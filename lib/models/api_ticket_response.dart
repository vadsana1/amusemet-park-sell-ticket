// import 'dart:convert';
import 'dart:developer'; // ເພື່ອໃຊ້ log

// ======================================================
// ▼▼▼ Helper Functions (ຄວນແຍກໄປໄຟລ໌ utils/safe_parser.dart) ▼▼▼
// ======================================================
int _safeParseInt(dynamic value, String fieldName) {
  if (value == null) {
    log('Warning: API returned null for "$fieldName". Using 0.');
    return 0;
  }

  // 🎯 [ເພີ່ມ] ລຶບເຄື່ອງໝາຍ (,) ອອກ​ກ່ອນ​ທີ່​ຈະ​ແປງ
  final String stringValue = value.toString().replaceAll(',', '');

  // ແປງ String ທີ່​ບໍ່​ມີ (,) ເປັນ int
  return int.tryParse(stringValue) ?? 0;
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
// ▲▲▲ Helper Functions (ສິ້ນສຸດ) ▲▲▲
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
  });

  // 🎯 [ແກ້ໄຂ] ປ່ຽນ Signature ຂອງ fromMap
  factory ApiTicketResponse.fromMap({
    // 1. Map ຂອງ Object ທີ່ຢູ່ໃນ "purchases" list
    required Map<String, dynamic> purchaseMap,
    // 2. Map ຂອງ JSON Response ໂຕເຕັມ (Root)
    required Map<String, dynamic> rootMap,
    // 3. ຈຳນວນຄົນ (ທີ່ເຮົາສົ່ງເຂົ້າไปเอง)
    required int globalAdultQty,
    required int globalChildQty,
  }) {
    List<String> extractedRideNames = [];

    // ສ່ວນນີ້ຖືກຕ້ອງ (ອ່ານ 'tickets' ຈາກ purchaseMap)
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

    return ApiTicketResponse(
      // --- ຂໍ້ມູນຈາກ purchaseMap ---
      purchaseId: _safeParseInt(purchaseMap['purchase_id'], 'purchase_id'),
      visitorUid: _safeParseString(purchaseMap['visitor_uid'], 'visitor_uid'),
      qrCode: _safeParseString(purchaseMap['qr_code'], 'qr_code'),

      // ⭐️ [ແກ້ໄຂ] ດຶງຄ່າຈາກ rootMap
      // ນີ້ຈະແກ້ໄຂ Warning "API returned null"
      amountDue: _safeParseInt(rootMap['amount_due'], 'amount_due'),
      amountPaid: _safeParseInt(rootMap['amount_paid'], 'amount_paid'),
      changeAmount: _safeParseInt(rootMap['change_amount'], 'change_amount'),

      // --- ຂໍ້ມູນທີ່ເຮົາ Enrich ใส่ ---
      rideNames: extractedRideNames,
      adultCount: globalAdultQty,
      childCount: globalChildQty,
    );
  }
}
