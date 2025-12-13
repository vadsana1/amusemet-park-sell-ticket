// lib/services/profile_api.dart

import "package:http/http.dart" as http;
import "dart:convert";
import '../models/theme_park_profile.dart';
import '../utils/url_helper.dart';

class ProfileApiService {
  Future<ThemeParkProfile> getProfile() async {
    try {
      final baseUrl = await getBaseUrl();
      final headers = await getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/api/themepark/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final dynamic data = jsonResponse['data'];

        return ThemeParkProfile.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }
}
