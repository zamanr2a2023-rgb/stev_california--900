import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/user_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';

class BookingQuote {
  const BookingQuote({
    required this.currency,
    required this.totalCents,
    required this.renizoFeeCents,
    required this.providerPayoutCents,
  });

  final String currency;
  final int totalCents;
  final int renizoFeeCents;
  final int providerPayoutCents;

  double get totalAmount => totalCents / 100.0;
}

/// POST /bookings/quote – returns pricing for selected options.
Future<BookingQuote> fetchBookingQuote({
  required String townId,
  required String serviceId,
  required String subsectionId,
  List<String> addonIds = const [],
}) async {
  final token = await AuthLocalStorage.getToken();
  final res = await http.post(
    Uri.parse(UserApi.bookingsQuote),
    headers: {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'townId': townId,
      'serviceId': serviceId,
      'subsectionId': subsectionId,
      'addonIds': addonIds,
    }),
  );
  final decoded = jsonDecode(res.body) as Map<String, dynamic>?;
  if (res.statusCode >= 400) {
    final msg = (decoded?['message'] ?? 'HTTP ${res.statusCode}').toString();
    throw Exception(msg);
  }
  final data = decoded?['data'] as Map<String, dynamic>? ?? {};
  int asInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
  return BookingQuote(
    currency: (data['currency'] ?? 'CAD').toString(),
    totalCents: asInt(data['totalCents']),
    renizoFeeCents: asInt(data['renizoFeeCents']),
    providerPayoutCents: asInt(data['providerPayoutCents']),
  );
}
