import 'dart:developer';
import '../models/api_ticket_response.dart';


class TicketPrinterService {
  
  Future<void> printTickets(
    List<ApiTicketResponse> tickets,
    String sellerName,
  ) async {
    log("⚠️ TicketPrinterService.printTickets ถูกเรียก แต่ถูกข้าม.");
    log("▶️ การพิมพ์ตั๋วได้ถูกย้ายไปทำใน ReceiptPage โดยใช้ Image Capture แทน.");
  }
}
