// lib/widgets/side_menu.dart

import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onMenuItemTapped;

  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.onMenuItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160.0,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      decoration: BoxDecoration(
        color: Colors.teal[400],
        borderRadius: BorderRadius.only(
          // VVVV ลบบรรทัดนี้ออก VVVV
          // topRight: Radius.circular(30.0), // <--- ลบออก
          // ^^^^ ลบบรรทัดนี้ออก ^^^^
          bottomRight: Radius.circular(30.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 50.0), // <--- ระยะห่างบนสุด

          MenuItem(
            title: "ປີ້ດ່ຽວ",
            icon: Icons.confirmation_number,
            isSelected: selectedIndex == 0,
            onTap: () => onMenuItemTapped(0),
          ),

          SizedBox(height: 30.0),

          MenuItem(
            title: "ປີ້ແພັກເກັດ",
            icon: Icons.airplane_ticket_outlined,
            isSelected: selectedIndex == 1,
            onTap: () => onMenuItemTapped(1),
          ),

          Spacer(),

          MenuItem(
            icon: Icons.person,
            isSelected: selectedIndex == 2,
            onTap: () => onMenuItemTapped(2),
            isProfile: true,
          ),

          SizedBox(height: 20.0),
        ],
      ),
    );
  }
}

// 4. Widget ย่อยสำหรับปุ่มเมนู
class MenuItem extends StatelessWidget {
  final String? title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isProfile;

  const MenuItem({
    super.key,
    this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        width: 120.0,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48.0,
              color: isSelected ? Colors.black : Colors.black,
            ),
            if (!isProfile) ...[
              SizedBox(height: 8.0),
              Text(
                title!,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
