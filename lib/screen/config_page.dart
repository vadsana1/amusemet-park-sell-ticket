import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  bool _obscureToken = true;
  bool _obscureBaseUrl = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      print('📖 [CONFIG] Loading config from storage...');
      final token = await _storage.read(key: 'base_token') ?? '';
      final baseUrl = await _storage.read(key: 'base_url') ?? '';

      print('📖 [CONFIG] Loaded:');
      print(
          '   Token: ${token.isEmpty ? "EMPTY" : "${token.substring(0, 10)}... (${token.length} chars)"}');
      print('   URL: ${baseUrl.isEmpty ? "EMPTY" : baseUrl}');

      setState(() {
        _tokenController.text = token;
        _baseUrlController.text = baseUrl;
      });
    } catch (e) {
      print('❌ [CONFIG] Load error: $e');
      _showMessage('Error loading config: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final token = _tokenController.text.trim();
        final url = _baseUrlController.text.trim();

        print('💾 [CONFIG] Saving config...');
        print('   Token: ${token.substring(0, 10)}... (${token.length} chars)');
        print('   URL: $url');

        await _storage.write(
          key: 'base_token',
          value: token,
        );
        await _storage.write(
          key: 'base_url',
          value: url,
        );

        // 🔍 Verify ว่า save สำเร็จ
        final savedToken = await _storage.read(key: 'base_token');
        final savedUrl = await _storage.read(key: 'base_url');
        print('✅ [CONFIG] Saved successfully!');
        print('   Verified Token: ${savedToken?.substring(0, 10)}...');
        print('   Verified URL: $savedUrl');

        _showMessage('ບັນທຶກຂໍ້ມູນສຳເລັດ!', isError: false);
      } catch (e) {
        _showMessage('ເກີດຂໍ້ຜິດພາດ: ${e.toString()}', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearConfig() async {
    final confirmed = await _showConfirmDialog();
    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _storage.delete(key: 'base_token');
        await _storage.delete(key: 'base_url');

        setState(() {
          _tokenController.clear();
          _baseUrlController.clear();
        });

        _showMessage('ລົບຂໍ້ມູນສຳເລັດ!', isError: false);
      } catch (e) {
        _showMessage('ເກີດຂໍ້ຜິດພາດ: ${e.toString()}', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _scanQrConfig() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _QrScannerPage(
          onScanned: (String data) {
            try {
              final Map<String, dynamic> json = jsonDecode(data);
              final String? baseUrl = json['base_url']?.toString();
              final String? token = json['token']?.toString();

              if (baseUrl != null && token != null) {
                setState(() {
                  _baseUrlController.text = baseUrl;
                  _tokenController.text = token;
                });
                _showMessage('ສະແກນສຳເລັດ! ກະລຸນາກົດບັນທຶກເພື່ອບັນທຶກຂໍ້ມູນ',
                    isError: false);
              } else {
                _showMessage('QR Code ບໍ່ຖືກຕ້ອງ: ຂາດຂໍ້ມູນ base_url ຫຼື token',
                    isError: true);
              }
            } catch (e) {
              _showMessage('ບໍ່ສາມາດອ່ານ QR Code ໄດ້: ຮູບແບບ JSON ບໍ່ຖືກຕ້ອງ',
                  isError: true);
            }
          },
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'ຢືນຢັນ',
            style: GoogleFonts.notoSansLao(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'ທ່ານຕ້ອງການລົບການຕັ້ງຄ່າທັງໝົດບໍ?',
            style: GoogleFonts.notoSansLao(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'ລົບ',
                style: GoogleFonts.notoSansLao(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'ຍົກເລີກ',
                style: GoogleFonts.notoSansLao(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.notoSansLao()),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    const Color mainColor = Color(0xFF15A19A);
    const Color fieldColor = Color(0xFFF0F0F0);

    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      maxLines: maxLines,
      style: GoogleFonts.notoSansLao(color: Colors.black87),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.notoSansLao(color: Colors.black54),
        prefixIcon: Icon(icon, color: mainColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: mainColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFF15A19A);
    const Color buttonColor = Color(0xFFE8DBB0);

    return Scaffold(
      backgroundColor: mainColor,
      appBar: AppBar(
        backgroundColor: mainColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ການຕັ້ງຄ່າແອັບ',
          style: GoogleFonts.notoSansLao(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Warning Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange.shade700,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'ໝາຍເຫດ: ນີ້ແມ່ນໜ້າການຕັ້ງຄ່າສຳລັບຜູ້ດູແລລະບົບເທົ່ານັ້ນ',
                                style: GoogleFonts.notoSansLao(
                                  color: Colors.orange.shade900,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Base URL Field
                      _buildTextField(
                        controller: _baseUrlController,
                        label: 'Base URL',
                        icon: Icons.link,
                        obscureText: _obscureBaseUrl,
                        maxLines: _obscureBaseUrl ? 1 : 3,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureBaseUrl
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFF15A19A),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureBaseUrl = !_obscureBaseUrl;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'ກະລຸນາໃສ່ Base URL';
                          }
                          if (!value.startsWith('http://') &&
                              !value.startsWith('https://')) {
                            return 'URL ຕ້ອງເລີ່ມຕົ້ນດ້ວຍ http:// ຫຼື https://';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // API Token Field
                      _buildTextField(
                        controller: _tokenController,
                        label: 'Token',
                        icon: Icons.vpn_key,
                        obscureText: _obscureToken,
                        maxLines: _obscureToken ? 1 : 3,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureToken
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFF15A19A),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureToken = !_obscureToken;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'ກະລຸນາໃສ່ API Token';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ຄຳແນະນຳ',
                                  style: GoogleFonts.notoSansLao(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '• Base URL: ທີ່ຢູ່ຂອງ API Server\n'
                              '• API Token: Token ສຳລັບການເຂົ້າເຖິງ API\n'
                              '• ກະລຸນາລະວັງໃນການກຳນົດຄ່າ',
                              style: GoogleFonts.notoSansLao(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Scan QR Button
                      ElevatedButton(
                        onPressed: _scanQrConfig,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.qr_code_scanner,
                                color: Color(0xFF15A19A)),
                            const SizedBox(width: 8),
                            Text(
                              'ສະແກນ QR ເພື່ອຕັ້ງຄ່າ',
                              style: GoogleFonts.notoSansLao(
                                color: const Color(0xFF15A19A),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Save Button
                      ElevatedButton(
                        onPressed: _saveConfig,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save, color: Colors.black87),
                            const SizedBox(width: 8),
                            Text(
                              'ບັນທຶກ',
                              style: GoogleFonts.notoSansLao(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Clear Button
                      OutlinedButton(
                        onPressed: _clearConfig,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.white, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ລົບການຕັ້ງຄ່າ',
                              style: GoogleFonts.notoSansLao(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// QR Scanner Page for scanning config JSON
class _QrScannerPage extends StatefulWidget {
  final Function(String) onScanned;

  const _QrScannerPage({required this.onScanned});

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      _hasScanned = true;
      final String data = barcodes.first.rawValue!;
      Navigator.of(context).pop();
      widget.onScanned(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF15A19A),
        title: Text(
          'ສະແກນ QR Config',
          style: GoogleFonts.notoSansLao(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),
          // Overlay with instructions
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(180),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'ສະແກນ QR Code ທີ່ມີຮູບແບບ JSON',
                    style: GoogleFonts.notoSansLao(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '{"base_url": "...", "token": "..."}',
                    style: GoogleFonts.robotoMono(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
