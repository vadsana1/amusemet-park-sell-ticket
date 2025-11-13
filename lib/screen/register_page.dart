import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/register.dart';
import '../services/register_api.dart';
import 'login_page.dart';
import 'about_page.dart';
import 'config_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _deviceIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _selectedProviderType;
  String _deviceId = '';
  bool _isLoading = false;

  String? _nameError;
  String? _providerTypeError;
  String? _locationError;

  final List<String> _providerTypes = ['pos', 'scanner', 'kiosk'];
  final RegisterApi _registerApi = RegisterApi();

  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _getDeviceId();
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getDeviceId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceId = '';

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      }

      setState(() {
        _deviceId = deviceId;
        _deviceIdController.text = deviceId;
      });
    } catch (e) {
      if (mounted) {
        _showErrorDialog('ບໍ່ສາມາດດຶງຂໍ້ມູນອຸປະກອນໄດ້: ${e.toString()}');
      }
    }
  }

  Future<void> _handleRegister() async {
    // Reset error messages
    setState(() {
      _nameError = null;
      _providerTypeError = null;
      _locationError = null;
    });

    // Validate inputs
    bool hasError = false;

    if (_nameController.text.isEmpty) {
      setState(() {
        _nameError = 'ກະລຸນາປ້ອນຊື່ອຸປະກອນ';
      });
      hasError = true;
    }

    if (_selectedProviderType == null || _selectedProviderType!.isEmpty) {
      setState(() {
        _providerTypeError = 'ກະລຸນາເລືອກປະເພດອຸປະກອນ';
      });
      hasError = true;
    }

    if (_locationController.text.isEmpty) {
      setState(() {
        _locationError = 'ກະລຸນາປ້ອນສະຖານທີ່';
      });
      hasError = true;
    }

    if (_deviceId.isEmpty) {
      _showErrorDialog('ບໍ່ສາມາດດຶງຂໍ້ມູນອຸປະກອນໄດ້');
      return;
    }

    if (hasError) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final registerData = Register(
        deviceId: _deviceId,
        deviceName: _nameController.text,
        deviceType: _selectedProviderType!,
        location: _locationController.text,
      );

      final success = await _registerApi.registerDevice(registerData);

      if (success) {
        if (mounted) {
          _showSuccessDialog('ລົງທະບຽນສຳເລັດ!');
        }
      } else {
        if (mounted) {
          _showErrorDialog('ລົງທະບຽນບໍ່ສຳເລັດ ກະລຸນາລອງໃໝ່');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('ເກີດຂໍ້ຜິດພາດ: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'ກະລຸນາຕຶດຕໍ່ແອດມິນ\n ໂທ: 020 9603 2493',
              style: TextStyle(
                fontSize: 13,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ສຳເລັດ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text('ຕົກລົງ'),
          ),
        ],
      ),
    );
  }

  void _handleInfoTap() {
    final now = DateTime.now();

    // Reset counter if more than 2 seconds have passed since last tap
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _tapCount = 0;
    }

    _tapCount++;
    _lastTapTime = now;

    if (_tapCount == 7) {
      // Navigate to Config page after 7 taps
      _tapCount = 0;
      _lastTapTime = null;
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ConfigPage()),
        ).then((_) {
          // Re-check device registration after returning from config page
          _checkDeviceRegistration();
        });
      }
    } else if (_tapCount == 1) {
      // Delay navigation to About page to allow for multiple taps
      Future.delayed(const Duration(seconds: 2), () {
        if (_tapCount == 1 && mounted) {
          // Only navigate if still at 1 tap after delay
          _tapCount = 0;
          _lastTapTime = null;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutPage()),
          );
        }
      });
    }
  }

  Future<void> _checkDeviceRegistration() async {
    final registerApi = RegisterApi();
    final storage = const FlutterSecureStorage();

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE0D8B0)),
                ),
                SizedBox(height: 20),
                Text('ກຳລັງກວດສອບອຸປະກອນ...', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      );
    }

    // Check if base_url and token are configured
    final baseUrl = await storage.read(key: 'base_url');
    final token = await storage.read(key: 'base_token');

    if (baseUrl == null || baseUrl.isEmpty || token == null || token.isEmpty) {
      // Config not set yet, close dialog and stay on register page
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    // Get device ID from hardware and verify with backend
    if (_deviceId.isNotEmpty && _deviceId != 'ກຳລັງໂຫຼດ...') {
      final isRegistered = await registerApi.verifyDevice(_deviceId);

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        if (isRegistered) {
          // Device exists in backend, go to login page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    } else {
      // Close loading dialog if device ID not ready
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: _handleInfoTap,
            tooltip: 'ຂໍ້ມູນ',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ລົງທະບຽນ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 40),

                _buildReadOnlyField(
                  controller: _deviceIdController,
                  hintText: 'Device ID',
                ),
                const SizedBox(height: 20),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      hintText: 'ຊື່ອຸປະກອນ',
                      hasError: _nameError != null,
                    ),
                    if (_nameError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 25.0, top: 5.0),
                        child: Text(
                          _nameError!,
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
                    _buildDropdownField(
                      hintText: 'ເລືອກປະເພດອຸປະກອນ',
                      value: _selectedProviderType,
                      items: _providerTypes,
                      hasError: _providerTypeError != null,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedProviderType = newValue;
                          _providerTypeError = null;
                        });
                      },
                    ),
                    if (_providerTypeError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 25.0, top: 5.0),
                        child: Text(
                          _providerTypeError!,
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
                      controller: _locationController,
                      hintText: 'ສະຖານທີ່',
                      hasError: _locationError != null,
                    ),
                    if (_locationError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 25.0, top: 5.0),
                        child: Text(
                          _locationError!,
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
                  onPressed: _isLoading ? null : _handleRegister,
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
                          'ລົງທະບຽນ',
                          style: TextStyle(color: Colors.black87, fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      enableInteractiveSelection: false,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[300],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 25.0,
        ),
      ),
      style: TextStyle(color: Colors.grey[700]),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool hasError = false,
  }) {
    return TextField(
      controller: controller,
      onChanged: (value) {
        if (hasError && value.isNotEmpty) {
          setState(() {
            if (controller == _nameController) {
              _nameError = null;
            } else if (controller == _locationController) {
              _locationError = null;
            }
          });
        }
      },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[200],
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 25.0,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String hintText,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool hasError = false,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[200],
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18.0,
          horizontal: 25.0,
        ),
      ),
      isExpanded: true,
    );
  }
}
