// lib/widgets/home_page_header.dart

import 'package:flutter/material.dart';

class HomePageHeader extends StatelessWidget {
  const HomePageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.0,
      color: Colors.teal[400], // <--- 1. เปลี่ยนสีพื้นหลังเป็น "สีเขียว"
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          // ไอคอนรูปดาว/โลก
          CircleAvatar(
            radius: 25.0,
            backgroundColor:
                Colors.purple[700], // ใส่สีพื้นหลังไว้กันรูปโหลดไม่ขึ้น
            child: ClipOval(
              // <--- 1. ใช้ ClipOval เพื่อตัดรูป
              child: Image.asset(
                'assets/images/logo.png', // <-- 2. Path ไปยังรูป
                fit: BoxFit.cover, // 3. สั่งให้รูปเต็มวงกลม
                width: 50.0, // (radius * 2)
                height: 50.0, // (radius * 2)
              ),
            )
          ),
          SizedBox(width: 15.0),

          // ข้อความ "ລະບົບຂາຍປີ້ສວນສະໜຸກ"
          Text(
            'ລະບົບຂາຍປີ້ສວນສະໜຸກ',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white, // <--- 2. เปลี่ยนสีข้อความเป็น "สีขาว"
            ),
          ),
          // (เราลบ Spacer และปุ่มเมนูออกไปแล้ว)
        ],
      ),
    );
  }
}
