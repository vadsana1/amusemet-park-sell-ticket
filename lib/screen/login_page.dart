import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      theme: ThemeData(
        fontFamily: 'NotoSansLao', 
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ເຂົ້າສູ່ລະບົບ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40),

              _buildTextField(
                controller: _usernameController,
                hintText: 'ຜູ້ໃຊງານ',
                prefixIcon: Icons.person_outline,
                suffixIcon: Icons.person_outline, 
                obscureText: false,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                controller: _passwordController,
                hintText: 'ລະຫັດ',
                prefixIcon: Icons.lock_outline,
                suffixIcon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  String username = _usernameController.text;
                  String password = _passwordController.text;
                  print('Username: $username');
                  print('Password: $password');
                  // ...
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0D8B0), 
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  elevation: 0, 
                ),
                child: const Text(
                  'ເຂົ້າສູ່ລະບົບ',
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                  },
                  child: const Text(
                    'ຊ່ວຍເຫຼືອ',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required IconData suffixIcon,
    required bool obscureText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[200], 
        prefixIcon: Icon(prefixIcon, color: Colors.black54),
        suffixIcon: Icon(suffixIcon, color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none, 
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
      ),
    );
  }
}
