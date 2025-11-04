import "package:http/http.dart" as http;
import "dart:convert";
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- [ເພີ່ມ] 1. ຕ້ອງ Import dotenv
import '../models/new_visitor_ticket.dart'; 

class VisitorApi {
 final String baseUrl;

 VisitorApi({String? baseUrl})
  : baseUrl = baseUrl ?? dotenv.env['api_url'] ?? '';

 Future<Map<String, dynamic>> sellDayPass(NewVisitorTicket newTicket) async {
  try {
   final response = await http.post(
    Uri.parse('$baseUrl/api/visitor/sell-day-pass'),
    headers: {
     'Content-Type': 'application/json; charset=UTF-8',
          // --- [ແກ້ໄຂ] 2. ເພີ່ມ 2 ແຖວນີ້ເຂົ້າໄປ (ຄືກັບຕົວຢ່າງ) ---
     'Authorization': 'Bearer ${dotenv.env['token'] ?? ''}',
     'X-Device-ID': dotenv.env['device_id'] ?? '',
          // --- [ສິ້ນສຸດການແກ້ໄຂ] ---
    },
    body: newTicket.toJson(),
   );

   final Map<String, dynamic> jsonResponse = json.decode(response.body);

   if (response.statusCode == 200 || response.statusCode == 201) {
    // ຖ້າສຳເລັດ
    return jsonResponse;
   } else {
    // ຖ້າບໍ່ສຳເລັດ (ເຊັ່ນ 400, 500)
    throw Exception(
     'Failed to sell pass: ${jsonResponse['message'] ?? response.body}',
    );
   }
  } catch (e) {
   // ຖ້າ Error (ເຊັ່ນ ບໍ່ມີເນັດ)
   throw Exception('Failed to connect to the server: $e');
  }
 }
}