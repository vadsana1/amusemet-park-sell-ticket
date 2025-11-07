// lib/screen/user_page.dart

import 'package:flutter/material.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          'ຜູ້ໃຊ້',
          style: TextStyle(fontSize: 24, color: Colors.black),
        ),
      ),
    );
  }
}
