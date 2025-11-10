import "package:http/http.dart" as http;
import "dart:convert";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import '../utils/url_helper.dart';

class ShiftApi {
  static const storage = FlutterSecureStorage();
  Future<Map<String, dynamic>> closeShift(String staffId) async {
    try {
      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/api/shift/close');
      final headers = await getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'staff_id': int.parse(staffId)}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'message': responseData['message'] ?? 'ປິດຮອບສຳເລັດ',
            'data': responseData['data'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'ປິດຮອບບໍ່ສຳເລັດ',
          };
        }
      } else if (response.statusCode == 403) {
        return {'success': false, 'message': 'ບໍ່ມີສິດໃນການປິດຮອບ'};
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
