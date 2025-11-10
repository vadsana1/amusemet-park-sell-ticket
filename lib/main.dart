import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ticket_app/screen/initialize_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amusement Park Demo',
      theme: ThemeData(primarySwatch: Colors.teal, fontFamily: 'Phetsarath_OT'),
      debugShowCheckedModeBanner: false,
      home: const InitializationPage(),
    );
  }
}
