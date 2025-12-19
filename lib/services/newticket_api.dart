import "package:http/http.dart" as http;
import "dart:convert";
import "dart:developer";
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

  Future<Map<String, dynamic>> sellDayPassSplit(
      Map<String, dynamic> payload) async {
    try {
      print('🚀 [API] sellDayPassSplit - START');
      log('🚀 [API] sellDayPassSplit - START');

      final baseUrl = await getBaseUrl();
      final headers = await getHeaders();

      final url = '$baseUrl/api/visitor/sell-day-pass/single-split';
      print('🌐 [API] URL: $url');
      log('🌐 [API] URL: $url');
      print('📤 [API] Request Payload: ${json.encode(payload)}');
      log('📤 [API] Request Payload: ${json.encode(payload)}');

      // Send to new endpoint: /api/visitor/sell-day-pass/single-split
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(payload),
      );

      print('📡 [API] Response Status Code: ${response.statusCode}');
      log('📡 [API] Response Status Code: ${response.statusCode}');
      print('📥 [API] Response Body: ${response.body}');
      log('📥 [API] Response Body: ${response.body}');

      final dynamic jsonResponse = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (jsonResponse is Map<String, dynamic>) {
          print('✅ [API] sellDayPassSplit - SUCCESS');
          log('✅ [API] sellDayPassSplit - SUCCESS');
          return jsonResponse;
        } else {
          // In case API might return a List in some cases (defensive)
          print('❌ [API] Unexpected format (not a Map)');
          log('❌ [API] Unexpected format (not a Map)');
          throw Exception('API returned unexpected format (not a Map).');
        }
      } else {
        // Handle error
        Map<String, dynamic> errorMap = {};
        if (jsonResponse is Map<String, dynamic>) {
          errorMap = jsonResponse;
        }
        print('❌ [API] Error: ${errorMap['message'] ?? response.body}');
        log('❌ [API] Error: ${errorMap['message'] ?? response.body}');
        throw Exception(
          'Failed to sell split pass: ${errorMap['message'] ?? response.body}',
        );
      }
    } catch (e) {
      print('💥 [API] Exception: $e');
      log('💥 [API] Exception: $e');
      throw Exception('Failed to connect to the server (Split): $e');
    }
  }
}
