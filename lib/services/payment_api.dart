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
      
      final response = await http.get(Uri.parse('$baseUrl/api/payment/list'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'] as List<dynamic>;

        
        return data
            .map((json) => PaymentMethod.fromMap(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to load payment methods: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }
}
