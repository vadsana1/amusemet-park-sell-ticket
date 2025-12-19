import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// Import Models and Services
import '../models/shift_report.dart';
import '../services/close_shift_api.dart';
import '../services/login_api.dart';
import 'login_page.dart';
import '../widgets/shift_report_popup.dart';

class ShiftSummaryScreen extends StatefulWidget {
  final String userId;
  const ShiftSummaryScreen({super.key, required this.userId});

  @override
  State<ShiftSummaryScreen> createState() => _ShiftSummaryScreenState();
}

class _ShiftSummaryScreenState extends State<ShiftSummaryScreen> {
  final ShiftApi _shiftApi = ShiftApi();
  final LoginApi _loginApi = LoginApi();

  bool _isLoading = true;
  String? _errorMessage;
  ShiftReport? _reportData;
  Map<String, dynamic>? _rawReportMap;

  // New summary data from api/shift/summary
  Map<String, dynamic>? _summaryData;

  final Color primaryColor = const Color(0xFF1A9A8B);
  final Color secondaryColor = const Color(0xFFFFA726);
  final Color bgColor = const Color(0xFFF0F2F5);

  @override
  void initState() {
    super.initState();
    _fetchShiftSummary();
  }

  /// Fetch dashboard summary from new API endpoint
  Future<void> _fetchShiftSummary() async {
    try {
      final summary = await _shiftApi.getShiftSummary();
      if (mounted) {
        setState(() {
          _summaryData = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Fetch close shift data (only when closing shift)
  Future<void> _fetchCloseShiftData() async {
    try {
      final response = await _shiftApi.closeShift(widget.userId);
      if (mounted) {
        setState(() {
          final reportMap = response['report'] ?? response;
          _rawReportMap = Map<String, dynamic>.from(reportMap);
          _reportData = ShiftReport.fromMap(reportMap);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _performCloseAndLogout() async {
    try {
      await _loginApi.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      // Ignore logout errors
    }
  }

  Future<void> _handleCloseShiftPress() async {
    // First, call close shift API to get the detailed report
    setState(() => _isLoading = true);
    await _fetchCloseShiftData();
    setState(() => _isLoading = false);

    if (_rawReportMap == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ບໍ່ສາມາດໂຫຼດຂໍ້ມູນປິດຮອບໄດ້')),
      );
      return;
    }

    final bool? shouldClose = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ShiftReportPopup(reportData: _rawReportMap!);
      },
    );

    if (shouldClose == true) {
      _performCloseAndLogout();
    }
  }

  String fmtNumber(num value) {
    return NumberFormat('#,###').format(value);
  }

  @override
  Widget build(BuildContext context) {
    // Use summary data from new API endpoint
    final summary = _summaryData;

    // Extract values from summary data
    final double totalSales = (summary?['total_sales'] ?? 0).toDouble();
    final double adultSales = (summary?['adult_sales'] ?? 0).toDouble();
    final double childSales = (summary?['child_sales'] ?? 0).toDouble();
    final int totalTickets = summary?['total_tickets'] ?? 0;
    final int totalVisitors = summary?['visitors']?['total'] ?? 0;
    final int adultVisitors = summary?['visitors']?['adults'] ?? 0;
    final int childVisitors = summary?['visitors']?['children'] ?? 0;
    final String displayDate =
        summary?['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String displayTime =
        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Dashboard ສະຫຼຸບຍອດ',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
              ? Center(
                  child: Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Pie chart
                            _buildSummaryCardFromApi(
                                totalSales, adultSales, childSales),

                            const SizedBox(height: 20),

                            // 2. Ticket data and visitors
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: _buildSimpleStatCard(
                                    'ຈຳນວນປີ້',
                                    '${fmtNumber(totalTickets)}',
                                    'ໃບ',
                                    Icons.confirmation_number_outlined,
                                    Colors.purple,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  flex: 1,
                                  child: _buildVisitorDetailedCard(
                                    adultVisitors,
                                    childVisitors,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // Close shift button
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 55,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleCloseShiftPress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE74C3C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'ຢືນຢັນປິດຮອບ (Close Shift)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // --- Widgets ---

  // Summary card using API data directly
  Widget _buildSummaryCardFromApi(
      double totalSales, double adult, double child) {
    List<PieChartSectionData> sections = [];
    if (adult == 0 && child == 0) {
      sections = [
        PieChartSectionData(
          color: Colors.grey[200],
          value: 1,
          radius: 15,
          showTitle: false,
        ),
      ];
    } else {
      sections = [
        PieChartSectionData(
          color: primaryColor,
          value: adult,
          radius: 18,
          showTitle: false,
        ),
        PieChartSectionData(
          color: secondaryColor,
          value: child,
          radius: 18,
          showTitle: false,
        ),
      ];
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 65,
                      startDegreeOffset: -90,
                      sections: sections,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ຍອດຂາຍທັງໝົດ',
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmtNumber(totalSales),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ກີບ',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 100, color: Colors.grey[200]),
          const SizedBox(width: 20),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ລາຍລະອຽດ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildLegendItem('ປີ້ຜູ້ໃຫຍ່', adult, primaryColor),
                const SizedBox(height: 15),
                _buildLegendItem('ປີ້ເດັກນ້ອຍ', child, secondaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Chart (kept for close shift popup)
  Widget _buildSummaryCard(ShiftReport data, double adult, double child) {
    List<PieChartSectionData> sections = [];
    if (adult == 0 && child == 0) {
      sections = [
        PieChartSectionData(
          color: Colors.grey[200],
          value: 1,
          radius: 15,
          showTitle: false,
        ),
      ];
    } else {
      sections = [
        PieChartSectionData(
          color: primaryColor,
          value: adult,
          radius: 18,
          showTitle: false,
        ),
        PieChartSectionData(
          color: secondaryColor,
          value: child,
          radius: 18,
          showTitle: false,
        ),
      ];
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 65,
                      startDegreeOffset: -90,
                      sections: sections,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Sales',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmtNumber(data.sales.totalSales),
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LAK',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 100, color: Colors.grey[200]),
          const SizedBox(width: 20),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ລາຍລະອຽດ (Details)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildLegendItem('Adult Sales', adult, primaryColor),
                const SizedBox(height: 15),
                _buildLegendItem('Child Sales', child, secondaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Text(
            fmtNumber(value),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }

  // 2. Stat card
  Widget _buildSimpleStatCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Visitor card
  Widget _buildVisitorDetailedCard(int adults, int children) {
    int total = adults + children;
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    color: Colors.blue[700],
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ຈຳນວນປິ້',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              Text(
                'ທັງໝົດ ${fmtNumber(total)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Divider(height: 1, color: Colors.black12),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'ຜູ້ໃຫຍ່',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      fmtNumber(adults),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 25, color: Colors.grey[200]),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: secondaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'ເດັກນ້ອຍ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      fmtNumber(children),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4. Payment list card (new: show all items) ---
  Widget _buildPaymentListCard(List<ReportPayment> payments) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.payment, size: 18, color: Colors.blue[700]),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Payment Methods (ຊ່ອງທາງການຊໍາລະ)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black12),

          // List Items Loop
          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('No payment data available'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 56,
                endIndent: 16,
                color: Colors.black12,
              ),
              itemBuilder: (context, index) {
                final payment = payments[index];

                // Define icon based on code
                IconData iconData;
                Color iconColor;
                Color iconBg;

                if (payment.code == 'CASH') {
                  iconData = Icons.monetization_on_outlined;
                  iconColor = Colors.green;
                  iconBg = Colors.green[50]!;
                } else if (payment.code == 'BANKTF') {
                  iconData = Icons.account_balance_outlined;
                  iconColor = Colors.blue;
                  iconBg = Colors.blue[50]!;
                } else {
                  iconData = Icons.credit_card;
                  iconColor = Colors.orange;
                  iconBg = Colors.orange[50]!;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(iconData, size: 20, color: iconColor),
                      ),
                      const SizedBox(width: 16),

                      // Method Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.method,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              payment.code,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Amount
                      Text(
                        fmtNumber(payment.total),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₭',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
