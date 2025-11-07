import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import '../models/ticket.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final bool isSelected;

  const TicketCard({
    Key? key,
    required this.ticket,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xFF1A9A8B);

    final Color borderColor = isSelected
        ? const Color.fromARGB(255, 227, 142, 3)
        : Colors.transparent;
    final double borderWidth = isSelected ? 3.0 : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        // [THAI FIX #1] 👈 ลด Padding หลัก
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- 1. ส่วนรูป (Placeholder) ---
            Container(
              // [THAI FIX #2] 👈 ลดขนาดรูป
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(26), // (0.1 opacity)
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Center(
                child: Icon(
                  Icons.local_activity, // ไอคอนชั่วคราว
                  color: Colors.white,
                  size: 30, // 👈 ลดขนาดไอคอนตาม
                ),
              ),
            ),
            // [THAI FIX #3] 👈 ลดระยะห่างแนวนอน
            const SizedBox(width: 12),

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
                      fontSize: 18, // [THAI FIX #4] 👈 ลดขนาดชื่อ
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // [THAI FIX #5] 👈 ลบ SizedBox แนวตั้งออก

                  // 2.2) ราคาผู้ใหญ่
                  Text(
                    "ຜູ້ໃຫຍ່: ${ticket.priceAdult.toStringAsFixed(0)} ກີບ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13, // [THAI FIX #6] 👈 ลดขนาดราคา
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // [THAI FIX #5] 👈 ลบ SizedBox แนวตั้งออก

                  // 2.3) ราคาเด็ก
                  Text(
                    "ເດັກ: ${ticket.priceChild.toStringAsFixed(0)} ກີບ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13, // [THAI FIX #6] 👈 ลดขนาดราคา
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
