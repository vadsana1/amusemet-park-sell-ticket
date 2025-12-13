import 'package:flutter/material.dart';
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
    // กำหนดสีพื้นหลังและสี Text ตามเงื่อนไข isSelected
    final Color cardColor = isSelected
        ? Colors.transparent
        : const Color(0xFF1A9A8B);
    final Color borderColor = isSelected
        ? const Color(0xFF1A9A8B)
        : Colors.transparent;
    final double borderWidth = isSelected ? 3.0 : 0.0;
    final Color contentColor = isSelected
        ? const Color(0xFF1A9A8B)
        : Colors.white;

    return InkWell(
      onTap: isSelected ? null : onTap,
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
            // --- ส่วนแสดงรูปภาพ (แก้ไขใหม่) ---
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.grey.withAlpha(25)
                    : Colors.white.withAlpha(
                        50,
                      ), // ปรับให้จางลงหน่อยเพื่อให้เห็นรูปชัดขึ้นถ้ารูปเป็น PNG ใส
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ClipRRect(
                // ใช้ ClipRRect เพื่อให้รูปภาพโค้งตามขอบ Container
                borderRadius: BorderRadius.circular(8.0),
                child: (ticket.imageUrl != null && ticket.imageUrl!.isNotEmpty)
                    ? Image.network(
                        ticket.imageUrl!,
                        fit: BoxFit.cover, // ให้รูปขยายเต็มพื้นที่
                        errorBuilder: (context, error, stackTrace) {
                          // กรณีโหลดรูปไม่ได้ ให้แสดง Icon เดิมแทน
                          return Center(
                            child: Icon(
                              Icons.local_activity,
                              color: contentColor,
                              size: 30,
                            ),
                          );
                        },
                      )
                    : Center(
                        // กรณีไม่มี URL ให้แสดง Icon เดิม
                        child: Icon(
                          Icons.local_activity,
                          color: contentColor,
                          size: 30,
                        ),
                      ),
              ),
            ),

            // ---------------------------------
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ticket.ticketName,
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1, // เพิ่ม maxLines เพื่อความสวยงาม
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "ຜູ້ໃຫຍ່: ${ticket.priceAdult.toStringAsFixed(0)} ກີບ",
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
