import 'dart:developer'; // เพื่อใช้ log

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

  // 🟢 [1] ตัวแปรวันที่
  final String purchaseDate;

  // 🟢 [2] ตัวแปร qrData สำหรับส่งไปพิมพ์
  final String qrData;

  // 🟢 [3] รายการวิธีการชำระเงิน
  final List<String> paymentMethods;

  // 🟢 [4] รายละเอียดการชำระเงินพร้อมยอดเงิน
  final List<Map<String, dynamic>> paymentDetails;

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
    required this.qrData,
    required this.paymentMethods,
    required this.paymentDetails,
  });

  factory ApiTicketResponse.fromMap({
    required Map<String, dynamic> purchaseMap,
    required Map<String, dynamic> rootMap,
    required int globalAdultQty,
    required int globalChildQty,
  }) {
    log('🎯 === ApiTicketResponse.fromMap STARTED ===');
    log('📦 purchaseMap keys: ${purchaseMap.keys.toList()}');
    log('📦 rootMap keys: ${rootMap.keys.toList()}');

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

          if (rideName.isEmpty &&
              rideMap['ticket_items'] != null &&
              (rideMap['ticket_items'] as List).isNotEmpty) {
            rideName = _safeParseString(
                rideMap['ticket_items'][0]['ticket_name'], 'ticket_name');
          }

          if (rideName.isNotEmpty) {
            extractedRideNames.add(rideName);
          }
        }
      }
    } catch (e) {
      log('Error parsing nested "tickets" array: $e');
    }

    int pId = _safeParseInt(purchaseMap['purchase_id'], 'purchase_id');
    String vUid = _safeParseString(purchaseMap['visitor_uid'], 'visitor_uid');

    String rawQrData = _safeParseString(purchaseMap['qr_data'], 'qr_data');
    String finalQrData = rawQrData.isNotEmpty
        ? rawQrData
        : '{"purchase":$pId,"visitor":"$vUid"}';

    String transactionDate = '';
    if (rootMap['payments'] != null &&
        (rootMap['payments'] as List).isNotEmpty) {
      transactionDate =
          _safeParseString(rootMap['payments'][0]['paid_at'], 'paid_at');
    }

    if (transactionDate.isEmpty) {
      transactionDate = _safeParseString(rootMap['created_at'], 'created_at');
    }
    if (transactionDate.isEmpty) {
      transactionDate = DateTime.now().toString();
    }

    int countAdult = 0;
    int countChild = 0;

    try {

      String directTicketType =
          _safeParseString(purchaseMap['ticket_type'], 'ticket_type')
              .toLowerCase();

      if (directTicketType.isNotEmpty && directTicketType != 'na') {
        log('Found ticket_type at purchase level: $directTicketType');
        if (directTicketType == 'adult') {
          countAdult = 1;
        } else if (directTicketType == 'child') {
          countChild = 1;
        }
      } else if (purchaseMap['tickets'] != null &&
          purchaseMap['tickets'] is List) {

        log('Counting from nested tickets array');
        for (var ticket in purchaseMap['tickets'] as List) {
          if (ticket is Map<String, dynamic>) {

            String ticketType =
                _safeParseString(ticket['ticket_type'], 'ticket_type')
                    .toLowerCase();


            if (ticketType.isEmpty || ticketType == 'na') {
              ticketType =
                  _safeParseString(ticket['visitor_type'], 'visitor_type')
                      .toLowerCase();
            }

            log('Ticket data: ticket_type=${ticket['ticket_type']}, visitor_type=${ticket['visitor_type']}, parsed=$ticketType');

            if (ticketType == 'adult') {
              countAdult++;
            } else if (ticketType == 'child') {
              countChild++;
            }
          }
        }
      }
    } catch (e) {
      log('Error counting adult/child from tickets: $e');
    }

    if (countAdult == 0 && countChild == 0) {
      log('Using fallback globalAdultQty=$globalAdultQty, globalChildQty=$globalChildQty');
      countAdult = globalAdultQty;
      countChild = globalChildQty;
    }

    log('Final count: Adult=$countAdult, Child=$countChild');

    List<String> extractedPaymentMethods = [];
    List<Map<String, dynamic>> extractedPaymentDetails = [];
    try {
      log('🔍 Checking payments in rootMap...');
      if (rootMap['payments'] != null && rootMap['payments'] is List) {
        log('✅ Found payments array with ${(rootMap['payments'] as List).length} items');
        for (var payment in rootMap['payments'] as List) {
          if (payment is Map<String, dynamic>) {
            String method =
                _safeParseString(payment['payment_method'], 'payment_method');

            int amount = _safeParseInt(payment['amount_paid'], 'amount_paid');

            log('  - Payment: method=$method, amount=$amount');
            if (method.isNotEmpty) {
              extractedPaymentMethods.add(method);
              extractedPaymentDetails.add({
                'method': method,
                'amount': amount,
              });
            }
          }
        }
      } else {
        log('⚠️ No payments array in rootMap');
      }

      if (extractedPaymentMethods.isEmpty) {
        log('🔄 Using fallback - extracting from purchaseMap/rootMap...');
        String paymentMethod = _safeParseString(
            purchaseMap['payment_method'] ?? rootMap['payment_method'],
            'payment_method');
        int amountPaid = _safeParseInt(
            purchaseMap['amount_paid'] ?? rootMap['amount_paid'],
            'amount_paid');

        log('  Fallback values: method=$paymentMethod, amountPaid=$amountPaid');
        if (paymentMethod.isNotEmpty) {
          extractedPaymentMethods.add(paymentMethod);
          extractedPaymentDetails.add({
            'method': paymentMethod,
            'amount': amountPaid,
          });
          log('  ✅ Added fallback payment: $paymentMethod ($amountPaid)');
        } else {
          log('  ❌ No payment method found in fallback');
        }
      }
    } catch (e) {
      log('❌ Error parsing payment_method: $e');
    }

    log('💳 Final Payment methods: ${extractedPaymentMethods.join(", ")}');
    log('💰 Final Payment details count: ${extractedPaymentDetails.length}');

    return ApiTicketResponse(
      purchaseId: pId,
      visitorUid: vUid,
      qrCode: _safeParseString(purchaseMap['qr_code'], 'qr_code'),

      qrData: finalQrData,

      amountDue: _safeParseInt(rootMap['amount_due'], 'amount_due'),
      amountPaid: _safeParseInt(rootMap['amount_paid'], 'amount_paid'),
      changeAmount: _safeParseInt(rootMap['change_amount'], 'change_amount'),

      purchaseDate: transactionDate,

      rideNames: extractedRideNames,
      adultCount: countAdult,
      childCount: countChild,
      paymentMethods: extractedPaymentMethods,
      paymentDetails: extractedPaymentDetails,
    );
  }
}
