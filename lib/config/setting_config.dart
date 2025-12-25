import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sticker_printer_service.dart';

class SettingConfig extends StatefulWidget {
  const SettingConfig({super.key});

  @override
  State<SettingConfig> createState() => _SettingConfigState();
}

class _SettingConfigState extends State<SettingConfig>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // เพิ่มเป็น 4 แท็บ
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFF15A19A);

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
          'ການຕັ້ງຄ່າ',
          style: GoogleFonts.notoSansLao(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.notoSansLao(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.notoSansLao(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.print, color: Colors.white),
              text: 'ການພິມ',
            ),
            Tab(
              icon: Icon(Icons.payment, color: Colors.white),
              text: 'ການຊຳລະ',
            ),
            Tab(
              icon: Icon(Icons.settings_input_antenna, color: Colors.white),
              text: 'ເຄື່ອງພິມ',
            ),
            Tab(
              icon: Icon(Icons.qr_code, color: Colors.white),
              text: 'QR จอสอง',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PrintSettingsTab(),
          PaymentSettingsTab(),
          PrinterConnectionTab(),
          // QrDualScreenTab(), // [เพิ่ม] แท็บใหม่สำหรับ QR จอสอง
        ],
      ),
    );
  }
}

// ===================================================================
// Tab 1: Print Settings (Auto Print, Display Time)
// ===================================================================
class PrintSettingsTab extends StatefulWidget {
  const PrintSettingsTab({super.key});

  @override
  State<PrintSettingsTab> createState() => _PrintSettingsTabState();
}

class _PrintSettingsTabState extends State<PrintSettingsTab> {
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  bool _autoPrintEnabled = true; // default: auto print
  int _displaySeconds = 4; // default: show for 4 seconds

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final autoPrint = await _storage.read(key: 'auto_print_enabled');
      final displayTime = await _storage.read(key: 'receipt_display_seconds');

      setState(() {
        _autoPrintEnabled = autoPrint != 'false'; // default true if not set
        _displaySeconds = int.tryParse(displayTime ?? '4') ?? 4;
      });
    } catch (e) {
      _showMessage('ເກີດຂໍ້ຜິດພາດໃນການໂຫຼດຂໍ້ມູນ: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await _storage.write(
        key: 'auto_print_enabled',
        value: _autoPrintEnabled.toString(),
      );
      await _storage.write(
        key: 'receipt_display_seconds',
        value: _displaySeconds.toString(),
      );

      _showMessage('ບັນທຶກການຕັ້ງຄ່າສຳເລັດ!', isError: false);
    } catch (e) {
      _showMessage('ເກີດຂໍ້ຜິດພາດ: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.notoSansLao()),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFF15A19A);
    const Color buttonColor = Color(0xFFE8DBB0);

    return SafeArea(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.print,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'ຕັ້ງຄ່າການພິມໃບຮັບເງິນອັດຕະໂນມັດ',
                            style: GoogleFonts.notoSansLao(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Auto Print Toggle Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _autoPrintEnabled ? Icons.print : Icons.touch_app,
                              color: mainColor,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ພິມອັດຕະໂນມັດ',
                                    style: GoogleFonts.notoSansLao(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _autoPrintEnabled
                                        ? 'ເປີດໃຊ້ງານ - ພິມທັນທີເມື່ອເຂົ້າໜ້າໃບຮັບເງິນ'
                                        : 'ປິດໃຊ້ງານ - ຕ້ອງກົດປຸ່ມພິມດ້ວຍຕົນເອງ',
                                    style: GoogleFonts.notoSansLao(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _autoPrintEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _autoPrintEnabled = value;
                                });
                              },
                              activeColor: mainColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Display Time Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.timer,
                              color: mainColor,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ເວລາສະແດງໜ້າໃບຮັບເງິນ',
                                    style: GoogleFonts.notoSansLao(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ໜ້າໃບຮັບເງິນຈະປິດອັດຕະໂນມັດຫຼັງຈາກ $_displaySeconds ວິນາທີ',
                                    style: GoogleFonts.notoSansLao(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: mainColor,
                                  thumbColor: mainColor,
                                  inactiveTrackColor: mainColor.withAlpha(50),
                                ),
                                child: Slider(
                                  value: _displaySeconds.toDouble(),
                                  min: 2,
                                  max: 15,
                                  divisions: 13,
                                  label: '$_displaySeconds ວິນາທີ',
                                  onChanged: (value) {
                                    setState(() {
                                      _displaySeconds = value.toInt();
                                    });
                                  },
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: mainColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_displaySeconds ວິ',
                                style: GoogleFonts.notoSansLao(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: mainColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ຄຳອະທິບາຍ',
                              style: GoogleFonts.notoSansLao(
                                color: Colors.blue.shade900,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• ເມື່ອເປີດ "ພິມອັດຕະໂນມັດ" ລະບົບຈະພິມໃບຮັບເງິນທັນທີເມື່ອເຂົ້າໜ້າ\n'
                          '• ເມື່ອປິດ "ພິມອັດຕະໂນມັດ" ຕ້ອງກົດປຸ່ມພິມດ້ວຍຕົນເອງ\n'
                          '• ໜ້າໃບຮັບເງິນຈະປິດອັດຕະໂນມັດຕາມເວລາທີ່ກຳນົດ\n'
                          '• ສາມາດກົດປຸ່ມກັບເພື່ອກັບໄປໜ້າຈ່າຍເງິນໄດ້',
                          style: GoogleFonts.notoSansLao(
                            color: Colors.blue.shade900,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save, color: Colors.black87),
                        const SizedBox(width: 8),
                        Text(
                          'ບັນທຶກການຕັ້ງຄ່າ',
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

                  // Reset to Default Button
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _autoPrintEnabled = true;
                        _displaySeconds = 4;
                      });
                      _showMessage(
                        'ຣີເຊັດເປັນຄ່າເລີ່ມຕົ້ນແລ້ວ ກະລຸນາກົດບັນທຶກ',
                        isError: false,
                      );
                    },
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
                          Icons.restore,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ຣີເຊັດເປັນຄ່າເລີ່ມຕົ້ນ',
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
    );
  }
}

// ===================================================================
// Tab 2: Payment Settings
// ===================================================================
class PaymentSettingsTab extends StatefulWidget {
  const PaymentSettingsTab({super.key});

  @override
  State<PaymentSettingsTab> createState() => _PaymentSettingsTabState();
}

class _PaymentSettingsTabState extends State<PaymentSettingsTab> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  int _refNumberMinLength = 6;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final refLength = await _storage.read(key: 'ref_number_min_length');
      if (mounted) {
        setState(() {
          _refNumberMinLength = int.tryParse(refLength ?? '6') ?? 6;
        });
      }
    } catch (e) {
      _showMessage('Error loading settings: $e', isError: true);
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _storage.write(
        key: 'ref_number_min_length',
        value: _refNumberMinLength.toString(),
      );
      _showMessage('ບັນທຶກການຕັ້ງຄ່າສຳເລັດ', isError: false);
    } catch (e) {
      _showMessage('Error saving: $e', isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.notoSansLao(),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFF15A19A);
    const Color buttonColor = Color(0xFFE8DBB0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [mainColor, Color(0xFF1a237e)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ref Number Min Length Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.pin,
                        color: mainColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ຈຳນວນຕົວເລກ Ref ຂັ້ນຕ່ຳ',
                              style: GoogleFonts.notoSansLao(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ກຳນົດຈຳນວນຕົວເລກຂັ້ນຕ່ຳທີ່ຕ້ອງໃສ່ເວລາໂອນເງິນ',
                              style: GoogleFonts.notoSansLao(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: mainColor,
                            thumbColor: mainColor,
                            inactiveTrackColor: mainColor.withAlpha(50),
                          ),
                          child: Slider(
                            value: _refNumberMinLength.toDouble(),
                            min: 4,
                            max: 20,
                            divisions: 16,
                            label: '$_refNumberMinLength ຕົວ',
                            onChanged: (value) {
                              setState(() {
                                _refNumberMinLength = value.toInt();
                              });
                            },
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: mainColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_refNumberMinLength ຕົວ',
                          style: GoogleFonts.notoSansLao(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: mainColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ຄຳອະທິບາຍ',
                        style: GoogleFonts.notoSansLao(
                          color: Colors.blue.shade900,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• ຈຳນວນຕົວເລກ Ref ຂັ້ນຕ່ຳໃຊ້ກັບການໂອນເງິນ (Bank Transfer)\n'
                    '• ລູກຄ້າຕ້ອງໃສ່ເລກ Ref ຢ່າງນ້ອຍຕາມຈຳນວນທີ່ກຳນົດ\n'
                    '• ຖ້າໃສ່ບໍ່ຄົບ ລະບົບຈະແຈ້ງເຕືອນ\n'
                    '• ແນະນຳໃຫ້ຕັ້ງຄ່າຕາມລະບົບທະນາຄານທີ່ໃຊ້',
                    style: GoogleFonts.notoSansLao(
                      color: Colors.blue.shade900,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Save Button
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, color: Colors.black87),
                  const SizedBox(width: 8),
                  Text(
                    'ບັນທຶກການຕັ້ງຄ່າ',
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

            // Reset to Default Button
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _refNumberMinLength = 6;
                });
                _showMessage(
                  'ຣີເຊັດເປັນຄ່າເລີ່ມຕົ້ນແລ້ວ ກະລຸນາກົດບັນທຶກ',
                  isError: false,
                );
              },
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
                    Icons.restore,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ຣີເຊັດເປັນຄ່າເລີ່ມຕົ້ນ',
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
    );
  }
}

// ===================================================================
// Tab 3: Printer Connection (Full Configuration)
// ===================================================================
class PrinterConnectionTab extends StatefulWidget {
  const PrinterConnectionTab({super.key});

  @override
  State<PrinterConnectionTab> createState() => _PrinterConnectionTabState();
}

class _PrinterConnectionTabState extends State<PrinterConnectionTab> {
  final StickerPrinterService _printerService = StickerPrinterService.instance;
  double _darknessLevel = 8.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkCurrentConnection();
    _listenToReconnectNotifier(); // 🆕 เริ่มฟังการแจ้งเตือนการเชื่อมต่อใหม่
  }

  @override
  void dispose() {
    // ไม่ต้อง dispose notifier เพราะเป็น singleton
    super.dispose();
  }

  // 🆕 ฟังการแจ้งเตือนการเชื่อมต่อใหม่
  void _listenToReconnectNotifier() {
    _printerService.needsReconnectNotifier.addListener(() {
      if (_printerService.needsReconnectNotifier.value && mounted) {
        _showReconnectDialog();
      }
    });
  }

  // 🆕 แสดง dialog เมื่อตรวจพบการเสียบ USB ใหม่
  void _showReconnectDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.usb, color: Color(0xFF15A19A), size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ຕ້ອງການເຊື່ອມຕໍ່ເຄື່ອງພິມ?',
                style: GoogleFonts.notoSansLao(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'ກວດພົບເຄື່ອງພິມຖືກເສັຽບເຂົ້າແລ້ວ\nຕ້ອງການເຊື່ອມຕໍ່ດຽວນີ້ບໍ?',
          style: GoogleFonts.notoSansLao(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _printerService.clearReconnectFlag();
              Navigator.pop(context);
            },
            child: Text(
              'ຍົກເລີກ',
              style: GoogleFonts.notoSansLao(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15A19A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              _printerService.clearReconnectFlag();

              // พยายามเชื่อมต่อใหม่
              await _printerService.autoConnectOnStartup();

              if (!mounted) return;
              final isConnected = _printerService.isConnectedNotifier.value;
              _showSnack(
                isConnected ? '✅ ເຊື່ອມຕໍ່ສຳເລັດ' : '❌ ເຊື່ອມຕໍ່ບໍ່ສຳເລັດ',
                isConnected ? const Color(0xFF27AE60) : const Color(0xFFC0392B),
              );
            },
            child: Text(
              'ເຊື່ອມຕໍ່',
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

  Future<void> _checkCurrentConnection() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await _printerService.checkConnection();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _darknessLevel = prefs.getDouble('printer_darkness') ?? 8.0;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('printer_darkness', _darknessLevel);
    _showSnack("ບັນທຶກສຳເລັດ", const Color(0xFF27AE60));
  }

  Future<void> _handleConnect() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // ปิดการตรวจสอบและแสดงรายการอุปกรณ์ USB ทั้งหมด (debug/log)
      // List<Map<String, dynamic>> devices = await _printerService.scanDevices();
      // if (mounted) Navigator.pop(context);
      // if (devices.isEmpty) {
      //   if (mounted) {
      //     _showSnack(
      //         "❌ ບໍ່ພົບ Printer USB ", const Color(0xFFC0392B));
      //   }
      //   return;
      // }
      // if (mounted) {
      //   showDialog(...)
      // }
      if (mounted) Navigator.pop(context);
      // ไม่ทำอะไรเมื่อกดปุ่ม Scan & Connect Printer
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      _showSnack("Error: $e", const Color(0xFFC0392B));
    }
  }

  Future<void> _connectToDevice(Map<String, dynamic> device) async {
    try {
      final success = await _printerService.connect(device);
      _printerService.setConnectionStatus(success, device);

      if (success) {
        _showSnack("✅ ເຊື່ອມຕໍ່ສຳເລັດ: ${device['productName']}",
            const Color(0xFF27AE60));
      } else {
        _showSnack("❌ ເຊື່ອມຕໍ່ບໍ່ສຳເລັດ", const Color(0xFFC0392B));
      }
    } catch (e) {
      _printerService.setConnectionStatus(false);
      _showSnack("❌ ເຊື່ອມຕໍ່ບໍ່ໄດ້: $e", const Color(0xFFC0392B));
    }
  }

  void _handleTestPrint() async {
    if (!_printerService.isConnectedNotifier.value) {
      _showSnack("ກະລຸນາເຊື່ອມຕໍ່ເຄື່ອງພິມກ່ອນ", const Color(0xFFC0392B));
      return;
    }

    // แสดง loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      debugPrint('🧪 [TEST PRINT] Starting test print with auto-retry...');

      await _printerService.printTicket(
        ticketId: "TEST-001",
        shopName: "TEST PRINT",
        date: "01/01/2025",
        time: "12:00",
        ticketType: "TEST MODE",
        rideList: ["Test Item 1", "Test Item 2"],
        qrData: "123456",
      );

      if (mounted) Navigator.pop(context);
      _showSnack("✅ ສົ່ງຄຳສັ່ງພິມສຳເລັດ", const Color(0xFF27AE60));
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('❌ [TEST PRINT] Error: $e');
      _showSnack("❌ ພິມບໍ່ສຳເລັດ: $e", const Color(0xFFC0392B));
    }
  }

  void _showSnack(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg,
              style: GoogleFonts.notoSansLao(fontWeight: FontWeight.bold)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFF15A19A);
    const Color successColor = Color(0xFF27AE60);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            ValueListenableBuilder<bool>(
              valueListenable: _printerService.isConnectedNotifier,
              builder: (context, isConnected, child) {
                final statusColor = isConnected ? successColor : Colors.red;
                final device = _printerService.getConnectedDeviceInfo();

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: statusColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isConnected ? Icons.check_circle : Icons.error,
                            color: statusColor,
                            size: 40,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isConnected
                                      ? "ເຊື່ອມຕໍ່ແລ້ວ"
                                      : "ຍັງບໍ່ເຊື່ອມຕໍ່",
                                  style: GoogleFonts.notoSansLao(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                Text(
                                  isConnected
                                      ? "ພ້ອມພິມ"
                                      : "ກະລຸນາເຊື່ອມຕໍ່ເຄື່ອງພິມ",
                                  style: GoogleFonts.notoSansLao(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // แสดงข้อมูลอุปกรณ์ถ้าเชื่อมต่ออยู่
                      if (isConnected && device != null) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          '📱 ອຸປະກອນ:',
                          style: GoogleFonts.notoSansLao(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${device['productName'] ?? 'Unknown Device'}',
                          style: GoogleFonts.notoSansLao(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        if (device['manufacturer'] != null &&
                            device['manufacturer'].toString().isNotEmpty)
                          Text(
                            '🏭 ${device['manufacturer']}',
                            style: GoogleFonts.notoSansLao(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'VID: ${device['vendorId']} | PID: ${device['productId']}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Scan & Connect Button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _handleConnect,
                icon: const Icon(Icons.usb),
                label: Text('Scan & Connect Printer',
                    style: GoogleFonts.notoSansLao(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Check Status & Reconnect Buttons
            ValueListenableBuilder<bool>(
              valueListenable: _printerService.isConnectedNotifier,
              builder: (context, isConnected, child) {
                if (!isConnected) return const SizedBox.shrink();

                return Column(
                  children: [
                    // Check Status Button
                    SizedBox(
                      height: 45,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final stillConnected =
                              await _printerService.checkConnection();
                          if (mounted) {
                            _showSnack(
                              stillConnected
                                  ? 'ເຊື່ອມຕໍ່ປົກກະຕິ'
                                  : 'ຕັດການເຊື່ອມຕໍ່ແລ້ວ',
                              stillConnected ? successColor : Colors.red,
                            );
                          }
                        },
                        icon: const Icon(Icons.wifi_find),
                        label: Text('Check Status',
                            style: GoogleFonts.notoSansLao()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueGrey,
                          side: const BorderSide(
                              color: Colors.blueGrey, width: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Reconnect Button
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _printerService.autoConnectOnStartup();
                          if (!mounted) return;

                          final isReconnected =
                              _printerService.isConnectedNotifier.value;
                          _showSnack(
                            isReconnected
                                ? 'ເຊື່ອມຕໍ່ໃໝ່ສຳເລັດ'
                                : 'ເຊື່ອມຕໍ່ໃໝ່ບໍ່ສຳເລັດ',
                            isReconnected ? successColor : Colors.orange,
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text('Reconnect (ຫຼັງປ່ຽນກະດາດ)',
                            style: GoogleFonts.notoSansLao()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: mainColor,
                          side: BorderSide(color: mainColor, width: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 🆕 Restart Connection Button - แก้ปัญหา connection ค้าง
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // แสดง loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (c) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          final success =
                              await _printerService.restartConnection();

                          if (mounted) Navigator.pop(context);
                          if (!mounted) return;

                          _showSnack(
                            success
                                ? '✅ Restart ສຳເລັດ - ລອງພິມໃໝ່ໄດ້ເລີຍ'
                                : '❌ Restart ບໍ່ສຳເລັດ',
                            success ? successColor : const Color(0xFFC0392B),
                          );
                        },
                        icon: const Icon(Icons.power_settings_new),
                        label: Text('Restart Connection (ແກ້ປັນຫາ)',
                            style: GoogleFonts.notoSansLao(fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 20),

            // Configuration Section
            Text(
              'ການຕັ້ງຄ່າ',
              style: GoogleFonts.notoSansLao(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Paper Size Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ຂະໜາດເຈ້ຍ:',
                      style: GoogleFonts.notoSansLao(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                  Text(
                    '60 x 40 mm (6 x 4 cm)',
                    style: GoogleFonts.notoSansLao(
                      fontSize: 16,
                      color: mainColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: Text('ບັນທຶກ',
                    style: GoogleFonts.notoSansLao(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: successColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Test Print Button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _handleTestPrint,
                icon: const Icon(Icons.print),
                label: Text('Test Print Sample',
                    style: GoogleFonts.notoSansLao(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
