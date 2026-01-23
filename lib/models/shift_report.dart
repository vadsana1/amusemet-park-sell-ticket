import 'dart:developer';

// --- Helper Functions ---

double _safeParseDouble(dynamic value) {
  if (value == null) return 0.0;
  // Convert String with commas (e.g. "1,940,000.00") to double
  return double.tryParse(value.toString().replaceAll(',', '')) ?? 0.0;
}

int _safeParseInt(dynamic value) {
  if (value == null) return 0;
  // Convert to int and handle decimal cases if present
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
  final List<ReportPayment> payments; // Store Bank Transfer, Cash list here
  final ReportRides rides;
  final String closedAt;

  ShiftReport({
    required this.user,
    required this.sales,
    required this.payments,
    required this.rides,
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
  final int totalAdultTickets;
  final int totalChildTickets;

  ReportSales({
    required this.totalSales,
    required this.adultSales,
    required this.childSales,
    required this.totalTickets,
    required this.totalAdultTickets,
    required this.totalChildTickets,
  });

  factory ReportSales.fromMap(Map<String, dynamic> map) {
    return ReportSales(
      totalSales: _safeParseDouble(map['total_sales']),
      adultSales: _safeParseDouble(map['adult_sales']),
      childSales: _safeParseDouble(map['child_sales']),
      totalTickets: _safeParseInt(map['total_tickets']),
      totalAdultTickets: _safeParseInt(map['total_adult_tickets']),
      totalChildTickets: _safeParseInt(map['total_child_tickets']),
    );
  }

  factory ReportSales.empty() {
    return ReportSales(
      totalSales: 0.0,
      adultSales: 0.0,
      childSales: 0.0,
      totalTickets: 0,
      totalAdultTickets: 0,
      totalChildTickets: 0,
    );
  }
}

// Model for Payment (Bank, Cash)
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
      // Use _safeParseDouble to support values like "1,940,000.00"
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
