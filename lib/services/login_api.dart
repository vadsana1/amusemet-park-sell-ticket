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
      print('🔐 [LOGIN] Attempting login for user: $login');

      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/api/device/login');
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'login': login, 'password': password}),
      );

      print('📡 [LOGIN] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Save user data if login successful
        if (responseData['status'] == 'success' &&
            responseData['user'] != null) {
          final user = responseData['user'];

          print('✅ [LOGIN] Login successful');
          print('   👤 User: ${user['name']}');
          print('   🎭 Role: ${user['role_name']} (ID: ${user['role_id']})');
          print('   🆔 User ID: ${user['user_id']}');
          print('   🔑 Is Admin: ${user['is_admin']}');

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
          await storage.write(
            key: 'is_admin',
            value: user['is_admin']?.toString() ?? '0',
          );

          print('💾 [LOGIN] User data saved to storage');

          return {'success': true, 'user': user};
        } else {
          print('❌ [LOGIN] Login failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Login failed',
          };
        }
      } else if (response.statusCode == 403) {
        print('🚫 [LOGIN] Access denied - Device not authorized');
        return {'success': false, 'message': 'ບໍ່ອະນຸຍາດໃຫ້ໃຊ້ຜ່ານອຸປະກອນນີ້'};
      } else {
        print('❌ [LOGIN] Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [LOGIN] Exception: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<bool> isUserLoggedIn() async {
    final userId = await storage.read(key: 'user_id');
    return userId != null && userId.isNotEmpty;
  }

  Future<void> logout() async {
    print('🚪 [LOGOUT] Logging out user');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'user_name');
    await storage.delete(key: 'role_id');
    await storage.delete(key: 'role_name');
    await storage.delete(key: 'is_admin');
    print('✅ [LOGOUT] User data cleared');
  }

// ✨ ตรวจสอบว่าเป็น admin/dev หรือไม่
  Future<bool> isAdmin() async {
    try {
      final isAdminValue = await storage.read(key: 'is_admin');
      final userId = await storage.read(key: 'user_id');
      final userName = await storage.read(key: 'user_name');

      print('🔍 [ROLE CHECK] Checking admin status...');
      print('   User ID: $userId');
      print('   User Name: $userName');
      print('   Is Admin: $isAdminValue');

      // ตรวจสอบจาก is_admin = 1
      if (isAdminValue == '1') {
        print('✅ [ROLE CHECK] User is ADMIN/DEV (is_admin = 1)');
        return true;
      }

      // สำรอง: เช็คจาก user_id = 1 หรือ 3 (Admin User)
      if (userId == '1' || userId == '3') {
        print('✅ [ROLE CHECK] User is ADMIN/DEV (user_id = $userId)');
        return true;
      }

      print('⚠️ [ROLE CHECK] User is NOT admin');
      return false;
    } catch (e) {
      print('❌ [ROLE CHECK] Error: $e');
      return false;
    }
  }

  // ดึงข้อมูล user ปัจจุบัน
  Future<Map<String, String?>> getCurrentUser() async {
    return {
      'user_id': await storage.read(key: 'user_id'),
      'user_name': await storage.read(key: 'user_name'),
      'role_id': await storage.read(key: 'role_id'),
      'role_name': await storage.read(key: 'role_name'),
      'is_admin': await storage.read(key: 'is_admin'),
    };
  }
}
