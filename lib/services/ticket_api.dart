import "package:http/http.dart" as http;
import "dart:convert";
import '../models/ticket.dart';
import '../utils/url_helper.dart';

class TicketApi {
  Future<List<Ticket>> fetchTickets() async {
    try {
      final baseUrl = await getBaseUrl();
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/ticket/list'),
        headers: headers,
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
