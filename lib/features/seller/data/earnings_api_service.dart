import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/provider_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';

/// Summary of net earnings (today, this week, month, all time).
class EarningsSummary {
  const EarningsSummary({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.allTime,
    this.currency = 'USD',
  });

  final String today;
  final String thisWeek;
  final String thisMonth;
  final String allTime;
  final String currency;

  double get todayDouble => double.tryParse(today) ?? 0;
  double get thisWeekDouble => double.tryParse(thisWeek) ?? 0;
  double get thisMonthDouble => double.tryParse(thisMonth) ?? 0;
  double get allTimeDouble => double.tryParse(allTime) ?? 0;

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      today: (json['today'] ?? '0.00').toString(),
      thisWeek: (json['thisWeek'] ?? '0.00').toString(),
      thisMonth: (json['thisMonth'] ?? '0.00').toString(),
      allTime: (json['allTime'] ?? '0.00').toString(),
      currency: (json['currency'] ?? 'USD').toString(),
    );
  }
}

/// Performance metrics for the provider.
class EarningsPerformance {
  const EarningsPerformance({
    this.totalJobsCompleted = 0,
    this.averageRating = 0,
    this.ratingCount = 0,
    this.averageResponseTime = '—',
    this.jobSuccessRate = 0,
  });

  final int totalJobsCompleted;
  final double averageRating;
  final int ratingCount;
  final String averageResponseTime;
  final int jobSuccessRate;

  factory EarningsPerformance.fromJson(Map<String, dynamic> json) {
    return EarningsPerformance(
      totalJobsCompleted: (json['totalJobsCompleted'] is int)
          ? json['totalJobsCompleted'] as int
          : int.tryParse(json['totalJobsCompleted']?.toString() ?? '0') ?? 0,
      averageRating: (json['averageRating'] is num)
          ? (json['averageRating'] as num).toDouble()
          : double.tryParse(json['averageRating']?.toString() ?? '0') ?? 0,
      ratingCount: (json['ratingCount'] is int)
          ? json['ratingCount'] as int
          : int.tryParse(json['ratingCount']?.toString() ?? '0') ?? 0,
      averageResponseTime: (json['averageResponseTime'] ?? '—').toString(),
      jobSuccessRate: (json['jobSuccessRate'] is int)
          ? json['jobSuccessRate'] as int
          : int.tryParse(json['jobSuccessRate']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Single transaction (completed job with earnings).
class EarningsTransactionItem {
  const EarningsTransactionItem({
    required this.id,
    required this.bookingId,
    required this.customerName,
    required this.serviceName,
    required this.completedAt,
    required this.amountEarnedCents,
    required this.amountEarned,
    required this.totalAmountCents,
    required this.totalAmount,
    this.currency = 'USD',
    this.status = 'completed',
  });

  final String id;
  final String bookingId;
  final String customerName;
  final String serviceName;
  final String completedAt;
  final int amountEarnedCents;
  final String amountEarned;
  final int totalAmountCents;
  final String totalAmount;
  final String currency;
  final String status;

  double get amountEarnedDouble => double.tryParse(amountEarned) ?? (amountEarnedCents / 100.0);
  double get totalAmountDouble => double.tryParse(totalAmount) ?? (totalAmountCents / 100.0);

  factory EarningsTransactionItem.fromJson(Map<String, dynamic> json) {
    return EarningsTransactionItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      bookingId: (json['bookingId'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      serviceName: (json['serviceName'] ?? '').toString(),
      completedAt: (json['completedAt'] ?? '').toString(),
      amountEarnedCents: (json['amountEarnedCents'] is int)
          ? json['amountEarnedCents'] as int
          : int.tryParse(json['amountEarnedCents']?.toString() ?? '0') ?? 0,
      amountEarned: (json['amountEarned'] ?? '0').toString(),
      totalAmountCents: (json['totalAmountCents'] is int)
          ? json['totalAmountCents'] as int
          : int.tryParse(json['totalAmountCents']?.toString() ?? '0') ?? 0,
      totalAmount: (json['totalAmount'] ?? '0').toString(),
      currency: (json['currency'] ?? 'USD').toString(),
      status: (json['status'] ?? 'completed').toString(),
    );
  }
}

/// Combined response from GET /providers/me/earnings.
class EarningsResponse {
  const EarningsResponse({
    required this.summary,
    required this.performance,
    required this.recentTransactions,
  });

  final EarningsSummary summary;
  final EarningsPerformance performance;
  final List<EarningsTransactionItem> recentTransactions;

  factory EarningsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final summary = data['summary'] is Map<String, dynamic>
        ? EarningsSummary.fromJson(Map<String, dynamic>.from(data['summary'] as Map))
        : const EarningsSummary(today: '0.00', thisWeek: '0.00', thisMonth: '0.00', allTime: '0.00');
    final performance = data['performance'] is Map<String, dynamic>
        ? EarningsPerformance.fromJson(Map<String, dynamic>.from(data['performance'] as Map))
        : const EarningsPerformance();
    final rawList = data['recentTransactions'];
    final List<EarningsTransactionItem> transactions = [];
    if (rawList is List) {
      for (final e in rawList) {
        if (e is Map<String, dynamic>) {
          transactions.add(EarningsTransactionItem.fromJson(e));
        } else if (e is Map) {
          transactions.add(EarningsTransactionItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return EarningsResponse(
      summary: summary,
      performance: performance,
      recentTransactions: transactions,
    );
  }
}

/// Fetches provider earnings (combined endpoint).
class EarningsApiService {
  Future<Map<String, String>?> _headers() async =>
      await AuthLocalStorage.authHeaders();

  /// GET /api/v1/providers/me/earnings – summary, performance, recent transactions.
  Future<EarningsResponse?> getEarnings({int transactionsLimit = 10}) async {
    final headers = await _headers();
    if (headers == null) return null;
    final uri = ProviderApi.earningsUri(transactionsLimit: transactionsLimit, limit: transactionsLimit);
    final res = await http.get(uri, headers: headers);
    if (res.statusCode != 200) return null;
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      if (body == null) return null;
      return EarningsResponse.fromJson(body);
    } catch (_) {
      return null;
    }
  }
}
