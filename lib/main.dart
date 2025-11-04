import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. Import dotenv
import 'screen/home_page.dart'; // import หน้า Home

Future<void> main() async {
  // 2. เปลี่ยน main ให้เป็น async

  // 3. ต้องเรียกอันนี้ก่อนเสมอ ถ้า main เป็น async
  WidgetsFlutterBinding.ensureInitialized();

  // 4. สั่งให้โหลดไฟล์ .env (รอจนเสร็จ)
  //    (ถ้าไฟล์ .env ของคุณชื่ออื่น ให้เปลี่ยนตรงนี้)
  await dotenv.load(fileName: ".env");

  // 5. ค่อยรันแอป
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amusement Park Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily:
            'Phetsarath_OT', // (แนะนำ: เพิ่มฟอนต์ภาษาลาวใน pubspec.yaml)
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(), // เรียกใช้หน้า Home
    );
  }
}
