// lib/widgets/home_page_header.dart

import 'package:flutter/material.dart';

class HomePageHeader extends StatelessWidget {
  const HomePageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.0,
      color: Colors.teal[400],
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25.0,
            backgroundColor: Colors.purple[700],
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png', 
                fit: BoxFit.cover,
                width: 50.0, 
                height: 50.0, 
              ),
            ),
          ),
          const SizedBox(width: 15.0),

          
          const Text(
            'ລະບົບຂາຍປີ້ສວນສະໜຸກ',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

      const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.error_outline,
              color: Colors.white, 
              size: 30.0, 
            ),
            onPressed: () {
              
              print('icon pressed!');
            },
          ),
        ],
      ),
    );
  }
}
