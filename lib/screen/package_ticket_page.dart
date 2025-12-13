// lib/screen/package_ticket_page.dart

import 'package:flutter/material.dart';

class PackageTicketPage extends StatelessWidget {
  const PackageTicketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Text(
            'ແພັກເກັດ',
            style: TextStyle(fontSize: 24, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
