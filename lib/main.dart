// [ FILE: lib/main.dart ]

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ticket_app/screen/initialize_page.dart';
// 💡 ลบ import 'dart:ui' as ui; และ import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // ❌ ลบ Logic การโหลด FontLoader ออกจากตรงนี้

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amusement Park Demo',
      theme: ThemeData(primarySwatch: Colors.teal, fontFamily: 'Phetsarath'),
      debugShowCheckedModeBanner: false,
      home: const InitializationPage(),
    );
  }
}
