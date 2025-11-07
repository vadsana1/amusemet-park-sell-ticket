import "package:http/http.dart" as http;
import "dart:convert";
import 'package:flutter_dotenv/flutter_dotenv.dart';
// 1. Import โมเดลใหม่
import '../models/payment_method.dart';

class PaymentApi {
  final String baseUrl;

  PaymentApi({String? baseUrl})
    : baseUrl = baseUrl ?? dotenv.env['api_url'] ?? '';

  // 2. เปลี่ยนชื่อฟังก์ชัน และประเภทข้อมูลที่ Return
  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/payment/list'),
        // ⭐️ FIX: ເພີ່ມ Headers ເພື່ອຢືນຢັນຕົວຕົນ ແລະ Device ID
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['token'] ?? ''}', // ໃຊ້ token
          'X-Device-ID': dotenv.env['device_id'] ?? '', // ໃຊ້ device_id
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // ຢືນຢັນວ່າ 'data' ເປັນ List
        final List<dynamic> data = jsonResponse['data'] as List<dynamic>;

        return data
            .map((json) => PaymentMethod.fromMap(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to load payment methods: ${response.statusCode}. Response body: ${response.body}',
        );
      }
    } catch (e) {
      // ໂຍນ Exception ທີ່ສື່ຄວາມໝາຍວ່າເຊື່ອມຕໍ່ບໍ່ໄດ້
      throw Exception('Failed to connect to the server or process data: $e');
    }
  }
}
