import "package:http/http.dart" as http;
import "dart:convert";
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/ticket.dart';

class TicketApi {
  final String baseUrl;

  TicketApi({String? baseUrl})
    : baseUrl = baseUrl ?? dotenv.env['api_url'] ?? '';

  Future<List<Ticket>> fetchTickets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/ticket/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['token'] ?? ''}',
          'X-Device-ID': dotenv.env['device_id'] ?? '',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'] as List<dynamic>;
        return data
            .map((json) => Ticket.fromMap(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load tickets: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }
}
