import "package:http/http.dart" as http;
import "dart:convert";
import '../utils/url_helper.dart';
// import '../models/new_visitor_ticket.dart';

class VisitorApi {
  Future<Map<String, dynamic>> sellDayPass(Map<String, dynamic> payload) async {
    try {
      final baseUrl = await getBaseUrl();
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/visitor/sell-day-pass'),
        headers: headers,
        body: json.encode(payload),
      );

      final dynamic jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (jsonResponse is Map<String, dynamic>) {
          return jsonResponse;
        } else {
          throw Exception('API (A) did not return a Map. Got List instead.');
        }
      } else {
        Map<String, dynamic> errorMap = jsonResponse as Map<String, dynamic>;
        throw Exception(
          'Failed to sell pass: ${errorMap['message'] ?? response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }
}
