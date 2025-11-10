import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/close_shift_api.dart';
import '../services/login_api.dart';
import 'login_page.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");
  final ShiftApi _shiftApi = ShiftApi();
  final LoginApi _loginApi = LoginApi();

  String _userName = 'Loading...';
  String _userId = '';
  bool _isClosingShift = false;

  // Mock data - replace with actual data from API
  final int _totalTickets = 10;
  final int _childTickets = 7;
  final int _adultTickets = 3;
  final double _totalRevenue = 100000;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final userName = await _storage.read(key: 'user_name');
    final userId = await _storage.read(key: 'user_id');
    if (mounted) {
      setState(() {
        _userName = userName ?? 'User';
        _userId = userId ?? '';
      });
    }
  }

  Future<void> _performCloseShift() async {
    if (_userId.isEmpty) {
      _showErrorDialog('ບໍ່ພົບຂໍ້ມູນຜູ້ໃຊ້ງານ');
      return;
    }

    setState(() {
      _isClosingShift = true;
    });

    try {
      final result = await _shiftApi.closeShift(_userId);

      if (mounted) {
        setState(() {
          _isClosingShift = false;
        });

        if (result['success'] == true) {
          // Show success and logout
          _showSuccessDialogAndLogout(result['message'] ?? 'ປິດຮອບສຳເລັດ');
        } else {
          _showErrorDialog(result['message'] ?? 'ປິດຮອບບໍ່ສຳເລັດ');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isClosingShift = false;
        });
        _showErrorDialog('ເກີດຂໍ້ຜິດພາດ: ${e.toString()}');
      }
    }
  }

  void _handleCloseShift() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ຢືນຢັນການປິດຮອບ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'ທ່ານຕ້ອງການປິດຮອບການຂາຍບໍ່?\nຫຼັງຈາກປິດຮອບ ທ່ານຈະຖືກອອກຈາກລະບົບ',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performCloseShift();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15A19A),
            ),
            child: const Text(
              'ຢືນຢັນປິດຮອບ',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ຍົກເລີກ'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ເກີດຂໍ້ຜິດພາດ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ຕົກລົງ'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialogAndLogout(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'ສຳເລັດ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              // Logout user
              await _loginApi.logout();
              // Navigate to login page
              if (mounted) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A9A8B),
            ),
            child: const Text('ຕົກລົງ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title Section
                    Text(
                      'ສະຫຼຸບຮອບການຂາຍ',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ຜູ້ຂາຍ: $_userName',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),

                    // Cards Row
                    Row(
                      children: [
                        // Total Tickets Card
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.confirmation_number,
                            title: 'ຍອດຂາຍທັງໝົດ',
                            mainValue: '$_totalTickets ປີ້',
                            details: [
                              _DetailRow(
                                label: 'ຜູ້ໃຫຍ່',
                                value: '$_adultTickets',
                              ),
                              _DetailRow(
                                label: 'ເດັກນ້ອຍ',
                                value: '$_childTickets',
                              ),
                            ],
                            color: const Color(0xFF1A9A8B),
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Total Revenue Card
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.attach_money,
                            title: 'ລາຍໄດ້ທັງໝົດ',
                            mainValue:
                                '${_currencyFormat.format(_totalRevenue)} ກີບ',
                            color: const Color(0xFF28B781),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // Close Shift Button
                    SizedBox(
                      width: 250,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isClosingShift ? null : _handleCloseShift,
                        icon: _isClosingShift
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.power_settings_new, size: 24),
                        label: Text(
                          _isClosingShift ? 'ກຳລັງປິດຮອບ...' : 'ປິດຮອບການຂາຍ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE74C3C),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'ກົດປຸ່ມດ້ານເທິງເພື່ອປິດຮອບແລະສ້າງລາຍງານ',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String mainValue,
    List<_DetailRow>? details,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Title Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Value
            Text(
              mainValue,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            // Details (if provided)
            if (details != null && details.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: details.map((detail) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            detail.label,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            detail.value,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow {
  final String label;
  final String value;

  _DetailRow({required this.label, required this.value});
}
