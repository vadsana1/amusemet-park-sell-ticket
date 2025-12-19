import "package:http/http.dart" as http;
import "dart:convert";
import '../models/payment_method.dart';
import '../utils/url_helper.dart';

class PaymentApi {
  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    try {
      final baseUrl = await getBaseUrl();
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/payment/list'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

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
      throw Exception('Failed to connect to the server or process data: $e');
    }
  }
}
