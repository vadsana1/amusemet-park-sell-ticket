import "package:http/http.dart" as http;
import "dart:convert";
import "package:flutter_secure_storage/flutter_secure_storage.dart";

class LoginApi {
  static const storage = FlutterSecureStorage();

  Future<String> _getBaseUrl() async {
    final storedUrl = await storage.read(key: 'base_url');
    return storedUrl ?? '';
  }

  Future<String?> _getDeviceId() async {
    return await storage.read(key: 'device_id');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await storage.read(key: 'base_token');
    final deviceId = await _getDeviceId();
    final language = await storage.read(key: 'language') ?? 'lo';

    return {
      'Authorization': 'Bearer $token',
      'X-Device-ID': deviceId ?? '',
      'Accept-Language': language,
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> login(String login, String password) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/api/device/login');
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'login': login, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Save user data if login successful
        if (responseData['status'] == 'success' &&
            responseData['user'] != null) {
          final user = responseData['user'];

          // Save user data to secure storage
          await storage.write(
            key: 'user_id',
            value: user['user_id'].toString(),
          );
          await storage.write(key: 'user_name', value: user['name'].toString());
          await storage.write(
            key: 'role_id',
            value: user['role_id'].toString(),
          );
          await storage.write(
            key: 'role_name',
            value: user['role_name'].toString(),
          );

          return {'success': true, 'user': user};
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Login failed',
          };
        }
      } else if (response.statusCode == 403) {
        return {'success': false, 'message': 'ບໍ່ອະນຸຍາດໃຫ້ໃຊ້ຜ່ານອຸປະກອນນີ້'};
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

  Future<bool> isUserLoggedIn() async {
    final userId = await storage.read(key: 'user_id');
    return userId != null && userId.isNotEmpty;
  }

  Future<void> logout() async {
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'user_name');
    await storage.delete(key: 'role_id');
    await storage.delete(key: 'role_name');
  }
}
