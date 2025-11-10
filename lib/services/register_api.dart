import "package:http/http.dart" as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/register.dart';

class RegisterApi {
  static const storage = FlutterSecureStorage();

  Future<String> _getBaseUrl() async {
    final storedUrl = await storage.read(key: 'base_url');
    return storedUrl ?? '';
  }

  Future<Map<String, String>> _getHeaders(String deviceId) async {
    final token = await storage.read(key: 'base_token');
    final language =
        await storage.read(key: 'language') ?? 'lo'; // Default to Lao language

    return {
      'Authorization': 'Bearer ${token ?? ''}',
      'X-Device-ID': deviceId,
      'Accept-Language': language,
      'Content-Type': 'application/json',
    };
  }

  Future<bool> isDeviceRegistered() async {
    final deviceId = await storage.read(key: 'device_id');
    return deviceId != null && deviceId.isNotEmpty;
  }

  Future<bool> registerDevice(Register registerData) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/api/device/register');
      final headers = await _getHeaders(registerData.deviceId);

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'device_id': registerData.deviceId,
          'device_name': registerData.deviceName,
          'device_type': registerData.deviceType,
          'location': registerData.location,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Save device_id from response to secure storage
        if (responseData['status'] == 'success' &&
            responseData['device_id'] != null) {
          await storage.write(
            key: 'device_id',
            value: responseData['device_id'],
          );
        }

        return true;
      } else {
        throw Exception('Failed to register device: ${response.statusCode}');
      }
    } catch (e) {
      throw ('');
    }
  }

  Future<bool> verifyDevice(String deviceId) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/api/device/verify');
      final headers = await _getHeaders(deviceId);

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'verify': true}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // If device exists in the system, save to storage
        if (responseData['status'] == 'success' &&
            responseData['device'] != null) {
          final device = responseData['device'];

          // Save device_id to storage
          await storage.write(
            key: 'device_id',
            value: device['device_id'] ?? deviceId,
          );

          // Save status
          if (device['status'] != null) {
            await storage.write(key: 'device_status', value: device['status']);
          }

          return true;
        }
        return false;
      } else {
        // Device not found or other error
        return false;
      }
    } catch (e) {
      // If verification fails, return false
      return false;
    }
  }
}
