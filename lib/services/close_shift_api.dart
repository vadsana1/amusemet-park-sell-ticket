import "package:http/http.dart" as http;
import "dart:convert";
import "dart:developer"; // 🎯 [ເພີ່ມ]
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

      // Log 1: ເບິ່ງ Body ທີ່ສົ່ງໄປ
      log('--- 📤 Closing Shift - Sending to API ---: $jsonBody');

      final response = await http.post(url, headers: headers, body: jsonBody);

      // 🎯 [ເພີ່ມ LOG ທີ່​ທ່ານ​ຖາມ​ຫາ] ເພື່ອເບິ່ງ JSON ດິບ
      log('--- Raw Shift Close Response ---: ${response.body}');

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
}
