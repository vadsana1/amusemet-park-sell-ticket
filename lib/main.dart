import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. Import dotenv

// 🎯 [FIX] ປ່ຽນເປັນ Package Import ເພື່ອໃຫ້ Dart ຊອກຫາ Class ເຫັນ
import 'package:ticket_app/screen/home_page.dart';

Future<void> main() async {
  // 2. ປ່ຽນ main ໃຫ້ເປັນ async

  // 3. ຕ້ອງເອີ້ນອັນນີ້ກ່ອນສະເໝີ ຖ້າ main ເປັນ async
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // 5. ຄ່ອຍຣັນແອັບ
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
            'Phetsarath_OT', // (ແນະນຳ: ເພີ່ມฟอนต์ພາສາລາວໃນ pubspec.yaml)
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(), // ເອີ້ນໃຊ້ໜ້າ Home
    );
  }
}
