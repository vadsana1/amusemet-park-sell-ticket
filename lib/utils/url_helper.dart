import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

/// Gets the base URL from secure storage
///
/// Returns the stored base URL or an empty string if not found.
/// Example usage:
/// ```dart
/// final baseUrl = await getBaseUrl();
/// final endpoint = '$baseUrl/api/user/login';
/// ```
Future<String> getBaseUrl() async {
  final storedUrl = await storage.read(key: 'base_url');
  return storedUrl ?? '';
}

/// Gets the device ID from secure storage
///
/// Returns the stored device ID or null if not found.
///
/// Example usage:
/// ```dart
/// final deviceId = await getDeviceId();
/// if (deviceId != null) {
///   print('Device ID: $deviceId');
/// }
/// ```
Future<String?> getDeviceId() async {
  return await storage.read(key: 'device_id');
}

/// Gets the standard HTTP headers required for API requests
///
/// Returns a map containing:
/// - Authorization: Bearer token from secure storage
/// - X-Device-ID: Device ID from secure storage
/// - Accept-Language: Language preference (default: 'lo')
/// - Content-Type: application/json
///
/// Example usage:
/// ```dart
/// import '../core/utils/url_helper.dart';
///
/// final headers = await getHeaders();
/// final response = await http.post(
///   Uri.parse('$baseUrl/api/endpoint'),
///   headers: headers,
///   body: json.encode(data),
/// );
/// ```
Future<Map<String, String>> getHeaders() async {
  final token = await storage.read(key: 'base_token');
  final deviceId = await getDeviceId();
  final language = await storage.read(key: 'language') ?? 'lo';

  return {
    'Authorization': 'Bearer ${token ?? ''}',
    'X-Device-ID': deviceId ?? '',
    'Accept-Language': language,
    'Content-Type': 'application/json',
  };
}
