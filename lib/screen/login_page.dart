import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/login_api.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _usernameError;
  String? _passwordError;

  final LoginApi _loginApi = LoginApi();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Reset error messages
    setState(() {
      _usernameError = null;
      _passwordError = null;
    });

    // Validate inputs
    bool hasError = false;

    if (_usernameController.text.isEmpty) {
      setState(() {
        _usernameError = 'ກະລຸນາປ້ອນຊື່ຜູ້ໃຊ້ງານ';
      });
      hasError = true;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'ກະລຸນາປ້ອນລະຫັດຜ່ານ';
      });
      hasError = true;
    }

    if (hasError) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _loginApi.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          // Login successful, navigate to home page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // Login failed, show error dialog
          _showErrorDialog(result['message'] ?? 'ເຂົ້າສູ່ລະບົບບໍ່ສຳເລັດ');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('ເກີດຂໍ້ຜິດພາດ: ${e.toString()}');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ເກີດຂໍ້ຜິດພາດ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              'ກະລຸນາຕິດຕໍ່ແອດມິນ\nໂທ: 020 9603 2493',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () async {
              final phoneNumber = '8562096032493';

              // Try WhatsApp URL scheme first (works better on mobile)
              final whatsappSchemeUrl = Uri.parse(
                'whatsapp://send?phone=$phoneNumber',
              );
              final whatsappWebUrl = Uri.parse('https://wa.me/$phoneNumber');

              try {
                // First try the app scheme
                bool launched = await launchUrl(
                  whatsappSchemeUrl,
                  mode: LaunchMode.externalApplication,
                );

                if (!launched) {
                  // If scheme fails, try web URL
                  launched = await launchUrl(
                    whatsappWebUrl,
                    mode: LaunchMode.externalApplication,
                  );
                }

                if (!launched) {
                  throw Exception('ບໍ່ສາມາດເປີດ WhatsApp ໄດ້');
                }
              } catch (e) {
                // Fallback to phone call if WhatsApp fails
                final telUrl = Uri.parse('tel:02096032493');
                try {
                  await launchUrl(telUrl);
                } catch (e) {
                  // Show error if both fail
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'ບໍ່ສາມາດເປີດ WhatsApp ຫຼື ໂທລະສັບໄດ້',
                          style: GoogleFonts.notoSansLao(),
                        ),
                      ),
                    );
                  }
                }
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.support_agent, color: Colors.green),
            label: Text(
              'ຕິດຕໍ່ແອດມິນ',
              style: GoogleFonts.notoSansLao(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'ປິດ',
              style: GoogleFonts.notoSansLao(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: SingleChildScrollView(
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

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _usernameController,
                      hintText: 'ຊື່ຜູ້ໃຊ້ງານ ຫຼື ອີເມວ',
                      prefixIcon: Icons.person_outline,
                      obscureText: false,
                      hasError: _usernameError != null,
                    ),
                    if (_usernameError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 25.0, top: 5.0),
                        child: Text(
                          _usernameError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _passwordController,
                      hintText: 'ລະຫັດຜ່ານ',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      hasError: _passwordError != null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.black54,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    if (_passwordError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 25.0, top: 5.0),
                        child: Text(
                          _passwordError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
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
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black87,
                            ),
                          ),
                        )
                      : const Text(
                          'ເຂົ້າສູ່ລະບົບ',
                          style: TextStyle(color: Colors.black87, fontSize: 16),
                        ),
                ),
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final phoneNumber = '8562096032493';

                      // Try WhatsApp URL scheme first (works better on mobile)
                      final whatsappSchemeUrl = Uri.parse(
                        'whatsapp://send?phone=$phoneNumber',
                      );
                      final whatsappWebUrl = Uri.parse(
                        'https://wa.me/$phoneNumber',
                      );

                      try {
                        // First try the app scheme
                        bool launched = await launchUrl(
                          whatsappSchemeUrl,
                          mode: LaunchMode.externalApplication,
                        );

                        if (!launched) {
                          // If scheme fails, try web URL
                          launched = await launchUrl(
                            whatsappWebUrl,
                            mode: LaunchMode.externalApplication,
                          );
                        }

                        if (!launched) {
                          throw Exception('ບໍ່ສາມາດເປີດ WhatsApp ໄດ້');
                        }
                      } catch (e) {
                        // Fallback to phone call if WhatsApp fails
                        final telUrl = Uri.parse('tel:02096032493');
                        try {
                          await launchUrl(telUrl);
                        } catch (e) {
                          // Show error if both fail
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'ບໍ່ສາມາດເປີດ WhatsApp ຫຼື ໂທລະສັບໄດ້',
                                  style: GoogleFonts.notoSansLao(),
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.help_outline,
                      color: Colors.black54,
                      size: 18,
                    ),
                    label: const Text(
                      'ຊ່ວຍເຫຼືອ',
                      style: TextStyle(color: Colors.black54, fontSize: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required bool obscureText,
    bool hasError = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: (value) {
        if (hasError && value.isNotEmpty) {
          setState(() {
            if (controller == _usernameController) {
              _usernameError = null;
            } else if (controller == _passwordController) {
              _passwordError = null;
            }
          });
        }
      },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[200],
        prefixIcon: Icon(prefixIcon, color: Colors.black54),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: hasError
              ? const BorderSide(color: Colors.red, width: 1.5)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: hasError
              ? const BorderSide(color: Colors.red, width: 1.5)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: hasError
              ? const BorderSide(color: Colors.red, width: 1.5)
              : const BorderSide(color: Color(0xFFE0D8B0), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0),
      ),
    );
  }
}
