import "package:http/http.dart" as http;
import "dart:convert";
import "dart:developer";
import '../utils/url_helper.dart'; // ຢ່າລືມ import ຕົວຊ່ວຍຂອງທ່ານ

class SellDayPassMultipleApi {
  // 1. 🎯 [ແກ້ໄຂ] ປ່ຽນ Return Type ເປັນ Map
  Future<Map<String, dynamic>> sellDayPassMultiple(
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
          final List<dynamic>? dataList =
              jsonResponse['purchases'] as List<dynamic>?;

          if (dataList != null) {
            // 2. 🎯 [ແກ້ໄຂ] ສົ່ງ Map ໂຕເຕັມກັບຄືນ
            return jsonResponse;
          } else {
            // This happens if the API succeeded but 'purchases' key was missing
            throw Exception(
              'API (B) returned a Map but is missing the expected "purchases" list.',
            );
          }
        } else {
          // Fallback if the API returns a raw list (ບໍ່ຄວນເກີດຂຶ້ນແລ້ວ)
          throw Exception('API (B) did not return expected Map format.');
        }
      } else {
        // Handle error status codes
        Map<String, dynamic> errorMap = jsonResponse as Map<String, dynamic>;
        throw Exception(
          'Failed to sell multiple passes: ${errorMap['message'] ?? response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }

  // 🆕 API สำหรับ Multiple Split Payment
  Future<Map<String, dynamic>> sellDayPassMultipleSplit(
    Map<String, dynamic> payload,
  ) async {
    try {
      print('🚀 [API] sellDayPassMultipleSplit - START');
      log('🚀 [API] sellDayPassMultipleSplit - START');

      final baseUrl = await getBaseUrl();
      final headers = await getHeaders();

      final url = '$baseUrl/api/visitor/sell-day-pass/multiple-split';
      print('🌐 [API] URL: $url');
      log('🌐 [API] URL: $url');
      print('📤 [API] Request Payload: ${json.encode(payload)}');
      log('📤 [API] Request Payload: ${json.encode(payload)}');

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
          final List<dynamic>? dataList =
              jsonResponse['purchases'] as List<dynamic>?;

          if (dataList != null) {
            print(
                '✅ [API] sellDayPassMultipleSplit - SUCCESS (${dataList.length} purchases)');
            log('✅ [API] sellDayPassMultipleSplit - SUCCESS (${dataList.length} purchases)');
            return jsonResponse;
          } else {
            print('❌ [API] Missing "purchases" key in response');
            log('❌ [API] Missing "purchases" key in response');
            throw Exception(
              'API returned a Map but is missing the expected "purchases" list.',
            );
          }
        } else {
          print('❌ [API] Unexpected response format (not a Map)');
          log('❌ [API] Unexpected response format (not a Map)');
          throw Exception('API did not return expected Map format.');
        }
      } else {
        Map<String, dynamic> errorMap = jsonResponse as Map<String, dynamic>;
        print('❌ [API] Error: ${errorMap['message'] ?? response.body}');
        log('❌ [API] Error: ${errorMap['message'] ?? response.body}');
        throw Exception(
          'Failed to sell multiple split passes: ${errorMap['message'] ?? response.body}',
        );
      }
    } catch (e) {
      print('💥 [API] Exception: $e');
      log('💥 [API] Exception: $e');
      throw Exception('Failed to connect to the server (Multiple Split): $e');
    }
  }
}
