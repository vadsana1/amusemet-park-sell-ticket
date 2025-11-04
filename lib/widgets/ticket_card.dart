import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import '../models/ticket.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final bool isSelected; // 1. เพิ่มตัวแปร IsSelected

  const TicketCard({
    Key? key,
    required this.ticket,
    this.onTap,
    this.isSelected = false, // 2. เพิ่มใน Constructor (ค่าเริ่มต้นคือ false)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xFF1A9A8B);

    // 3. กำหนดสีขอบเมื่อถูกเลือก
    final Color borderColor = isSelected
        ? const Color.fromARGB(255, 227, 142, 3)
        : Colors.transparent;
    final double borderWidth = isSelected ? 3.0 : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12.0),
          // 4. เพิ่มขอบตามเงื่อนไข isSelected
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- 1. ส่วนรูป (Placeholder) ---
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26), // (0.1 opacity)
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Center(
                child: Icon(
                  Icons.local_activity, // ไอคอนชั่วคราว
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // --- 2. ส่วนข้อความ (ดึงจาก Model) ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 2.1) ชื่อ Ticket (จาก Model)
                  Text(
                    ticket.ticketName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // 2.2) ราคา (จาก Model)
                  Text(
                    "${ticket.priceAdult.toStringAsFixed(0)} ກີບ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
