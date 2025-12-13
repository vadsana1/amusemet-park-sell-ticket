import "package:http/http.dart" as http;
import "dart:convert";
import '../utils/url_helper.dart';

class ShiftApi {
  Future<Map<String, dynamic>> closeShift(String staffId) async {
    try {
      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/api/shift/close');
      final headers = await getHeaders();

      final Map<String, dynamic> payload = {
        'staff_id': int.tryParse(staffId) ?? 0,
      };
      final String jsonBody = jsonEncode(payload);

      final response = await http.post(url, headers: headers, body: jsonBody);

      final dynamic responseData = jsonDecode(response.body);

      if (responseData is! Map<String, dynamic>) {
        throw Exception('API response is not a valid Map.');
      }

      if (response.statusCode == 200) {
        if (responseData['status'] == 'success') {
          if (responseData['report'] is Map<String, dynamic>) {
            return responseData['report'] as Map<String, dynamic>;
          } else {
            throw Exception(
              'API returned success but data is missing or invalid.',
            );
          }
        } else {
          throw Exception(
            responseData['message'] ?? 'An unknown error occurred.',
          );
        }
      } else {
        throw Exception(
          responseData['message'] ??
              'Failed to close shift: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get shift summary data without closing the shift
  /// GET api/shift/summary
  Future<Map<String, dynamic>> getShiftSummary() async {
    try {
      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/api/shift/summary');
      final headers = await getHeaders();

      final response = await http.get(url, headers: headers);

      final dynamic responseData = jsonDecode(response.body);

      if (responseData is! Map<String, dynamic>) {
        throw Exception('API response is not a valid Map.');
      }

      if (response.statusCode == 200) {
        if (responseData['status'] == 'success') {
          if (responseData['data'] is Map<String, dynamic>) {
            return responseData['data'] as Map<String, dynamic>;
          } else {
            throw Exception(
              'API returned success but data is missing or invalid.',
            );
          }
        } else {
          throw Exception(
            responseData['message'] ?? 'An unknown error occurred.',
          );
        }
      } else {
        throw Exception(
          responseData['message'] ??
              'Failed to get shift summary: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
