import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import '../models/ticket.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final bool isSelected;

  const TicketCard({
    super.key,
    required this.ticket,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Change background to transparent when selected, keep solid when not selected
    final Color cardColor = isSelected
        ? Colors.transparent
        : const Color(0xFF1A9A8B);

    final Color borderColor = isSelected
        ? const Color(0xFF1A9A8B)
        : Colors.transparent;
    final double borderWidth = isSelected ? 3.0 : 0.0;

    // Text and icon color - teal when selected, white when not
    final Color contentColor = isSelected
        ? const Color(0xFF1A9A8B)
        : Colors.white;

    return InkWell(
      onTap: isSelected ? null : onTap, // Disable tap when already selected
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.grey.withAlpha(25)
                    : Colors.white.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Icon(
                  Icons.local_activity,
                  color: contentColor,
                  size: 30,
                ),
              ),
            ),
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
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 2.2) ราคาผู้ใหญ่
                  Text(
                    "ຜູ້ໃຫຍ່: ${ticket.priceAdult.toStringAsFixed(0)} ກີບ",
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // 2.3) ราคาเด็ก
                  Text(
                    "ເດັກ: ${ticket.priceChild.toStringAsFixed(0)} ກີບ",
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 13,
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
