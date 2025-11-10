import "package:http/http.dart" as http;
import "dart:convert";
import '../utils/url_helper.dart';
// import '../models/new_visitor_ticket.dart'; // ❌ ບໍ່ຈຳເປັນຕ້ອງໃຊ້ NewVisitorTicket ແລ້ວ

class VisitorApi {
  Future<Map<String, dynamic>> sellDayPass(
    // 🎯 [ແກ້ໄຂ] ປ່ຽນ Type ຈາກ NewVisitorTicket ເປັນ Map
    Map<String, dynamic> payload,
  ) async {
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

  // --- 2. API (B) ສຳລັບຫຼາຍ QR (ແກ້ໄຂໃຫ້ຮັບ Map) ---
  Future<List<dynamic>> sellDayPassMultiple(
    Map<String, dynamic> payload,
  ) async {
    try {
      final baseUrl = await getBaseUrl();
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/visitor/sell-day-pass/multiple'),
        headers: headers,
        body: json.encode(payload),
      );

      final dynamic jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (jsonResponse is Map<String, dynamic>) {
          // 🎯 FIX: CHANGE THE KEY FROM 'data' or 'tickets' to 'purchases'
          final List<dynamic>? dataList =
              jsonResponse['purchases'] as List<dynamic>?;

          if (dataList != null) {
            return dataList; // ✅ Returns the list of purchase objects
          } else {
            // This happens if the API succeeded but 'purchases' key was missing
            throw Exception(
              'API (B) returned a Map but is missing the expected "purchases" list.',
            );
          }
        } else if (jsonResponse is List) {
          // Fallback if the API returns a raw list
          return jsonResponse;
        } else {
          throw Exception('API (B) did not return expected data format.');
        }
      } else {
        // Handle error status codes (same as before)
        Map<String, dynamic> errorMap = jsonResponse as Map<String, dynamic>;
        throw Exception(
          'Failed to sell multiple passes: ${errorMap['message'] ?? response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }
}
