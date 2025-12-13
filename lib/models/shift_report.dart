import 'dart:developer';

// --- Helper Functions ---

double _safeParseDouble(dynamic value) {
  if (value == null) return 0.0;
  // แปลง String ที่มีลูกน้ำ (เช่น "1,940,000.00") ให้เป็น double
  return double.tryParse(value.toString().replaceAll(',', '')) ?? 0.0;
}

int _safeParseInt(dynamic value) {
  if (value == null) return 0;
  // แปลงเป็น int และจัดการกรณีทศนิยมถ้ามี
  if (value is double) return value.toInt();
  return int.tryParse(value.toString().split('.').first) ?? 0;
}

String _safeParseString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

// --- Main Model ---

class ShiftReport {
  final ReportUser user;
  final ReportSales sales;
  final List<ReportPayment> payments; // เก็บรายการ Bank Transfer, Cash ที่นี่
  final ReportRides rides;
  final ReportVisitors visitors;
  final String closedAt;

  ShiftReport({
    required this.user,
    required this.sales,
    required this.payments,
    required this.rides,
    required this.visitors,
    required this.closedAt,
  });

  factory ShiftReport.fromMap(Map<String, dynamic> map) {
    try {
      return ShiftReport(
        user: ReportUser.fromMap(map['user'] ?? {}),
        sales: ReportSales.fromMap(map['sales'] ?? {}),

        // Map Payments List
        payments: (map['payments'] as List<dynamic>? ?? [])
            .map((payment) => ReportPayment.fromMap(payment))
            .toList(),

        rides: ReportRides.fromMap(map['rides'] ?? {}),
        visitors: ReportVisitors.fromMap(map['visitors'] ?? {}),
        closedAt: _safeParseString(map['closed_at']),
      );
    } catch (e) {
      log('Error parsing ShiftReport: $e');
      return ShiftReport.empty();
    }
  }

  factory ShiftReport.empty() {
    return ShiftReport(
      user: ReportUser.empty(),
      sales: ReportSales.empty(),
      payments: [],
      rides: ReportRides.empty(),
      visitors: ReportVisitors.empty(),
      closedAt: '',
    );
  }
}

// --- Sub-Models ---

class ReportUser {
  final int staffId;
  final String staffName;
  final String reportTime;

  ReportUser({
    required this.staffId,
    required this.staffName,
    required this.reportTime,
  });

  factory ReportUser.fromMap(Map<String, dynamic> map) {
    return ReportUser(
      staffId: _safeParseInt(map['staff_id']),
      staffName: _safeParseString(map['staff_name']),
      reportTime: _safeParseString(map['report_time']),
    );
  }

  factory ReportUser.empty() {
    return ReportUser(staffId: 0, staffName: '', reportTime: '');
  }
}

class ReportSales {
  final double totalSales;
  final double adultSales;
  final double childSales;
  final int totalTickets;

  ReportSales({
    required this.totalSales,
    required this.adultSales,
    required this.childSales,
    required this.totalTickets,
  });

  factory ReportSales.fromMap(Map<String, dynamic> map) {
    return ReportSales(
      totalSales: _safeParseDouble(map['total_sales']),
      adultSales: _safeParseDouble(map['adult_sales']),
      childSales: _safeParseDouble(map['child_sales']),
      totalTickets: _safeParseInt(map['total_tickets']),
    );
  }

  factory ReportSales.empty() {
    return ReportSales(
      totalSales: 0.0,
      adultSales: 0.0,
      childSales: 0.0,
      totalTickets: 0,
    );
  }
}

// Model สำหรับ Payment (Bank, Cash)
class ReportPayment {
  final String method;
  final String code;
  final double total;

  ReportPayment({
    required this.method,
    required this.code,
    required this.total,
  });

  factory ReportPayment.fromMap(Map<String, dynamic> map) {
    return ReportPayment(
      method: _safeParseString(map['method']),
      code: _safeParseString(map['code']),
      // ใช้ _safeParseDouble เพื่อรองรับค่า "1,940,000.00"
      total: _safeParseDouble(map['total']),
    );
  }
}

class ReportRides {
  final int totalPlays;
  final int adultsPlayed;
  final int childrenPlayed;

  ReportRides({
    required this.totalPlays,
    required this.adultsPlayed,
    required this.childrenPlayed,
  });

  factory ReportRides.fromMap(Map<String, dynamic> map) {
    return ReportRides(
      totalPlays: _safeParseInt(map['total_plays']),
      adultsPlayed: _safeParseInt(map['adults_played']),
      childrenPlayed: _safeParseInt(map['children_played']),
    );
  }

  factory ReportRides.empty() {
    return ReportRides(totalPlays: 0, adultsPlayed: 0, childrenPlayed: 0);
  }
}

class ReportVisitors {
  final int totalAdults;
  final int totalChildren;
  final int totalVisitors;

  ReportVisitors({
    required this.totalAdults,
    required this.totalChildren,
    required this.totalVisitors,
  });

  factory ReportVisitors.fromMap(Map<String, dynamic> map) {
    int adults = _safeParseInt(map['total_adults']);
    int children = _safeParseInt(map['total_children']);

    return ReportVisitors(
      totalAdults: adults,
      totalChildren: children,
      totalVisitors: map['total_visitors'] != null
          ? _safeParseInt(map['total_visitors'])
          : (adults + children),
    );
  }

  factory ReportVisitors.empty() {
    return ReportVisitors(totalAdults: 0, totalChildren: 0, totalVisitors: 0);
  }
}
