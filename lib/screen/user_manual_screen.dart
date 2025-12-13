// ไฟล์: user_manual_screen.dart
import 'package:flutter/material.dart';

class UserManualScreen extends StatelessWidget {
  const UserManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'ຄູ່ມືຜູ້ໃຊ້',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A9A8B),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          _ManualItem(
            title: 'ວິທີໃຊ້ງານແອັບ',
            content:
                '1. ',
            icon: Icons.start,
          ),
          
       
         
        ],
      ),
    );
  }
}

// Widget ย่อยสำหรับแสดงแต่ละหัวข้อ เพื่อให้โค้ดสะอาด
class _ManualItem extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _ManualItem({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: const Color(0xFF1A9A8B)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              content,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
