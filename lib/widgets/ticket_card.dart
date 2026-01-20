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
    // Set background color and text color based on isSelected condition
    final Color cardColor =
        isSelected ? Colors.transparent : const Color(0xFF1A9A8B);
    final Color borderColor =
        isSelected ? const Color(0xFF1A9A8B) : Colors.transparent;
    final double borderWidth = isSelected ? 3.0 : 0.0;
    final Color contentColor =
        isSelected ? const Color(0xFF1A9A8B) : Colors.white;

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
            // --- Image display section (modified) ---
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.grey.withAlpha(25)
                    : Colors.white.withAlpha(
                        50,
                      ), // Adjust to make more transparent so PNG images show clearer
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ClipRRect(
                // Use ClipRRect to round image corners matching Container
                borderRadius: BorderRadius.circular(8.0),
                child: (ticket.imageUrl != null && ticket.imageUrl!.isNotEmpty)
                    ? Image.network(
                        ticket.imageUrl!,
                        fit: BoxFit.cover, // Expand image to fill area
                        errorBuilder: (context, error, stackTrace) {
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
                        // If no URL, show original icon
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2, // Allow 2 lines for long names
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
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
