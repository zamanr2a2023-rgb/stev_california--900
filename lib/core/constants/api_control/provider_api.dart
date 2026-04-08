import 'global_api.dart' as global;

class ProviderApi {
  static String get api => global.api;
  static String get profileScreen => "$api/providers/me/profile";
  static String get dashboard => "$api/providers/me/dashboard";
  static String get myBookings => "$api/bookings/provider/me";
  static String bookingById(String bookingId) => "$api/bookings/provider/$bookingId";
  static String bookingAccept(String bookingId) => "$api/bookings/$bookingId/accept";
  static String bookingReject(String bookingId) => "$api/bookings/$bookingId/rejected";
  static String bookingComplete(String bookingId) => "$api/bookings/$bookingId/complete";
  static String get catalogServices => "$api/catalog/services";
  static Uri catalogSubSectionsUri(String serviceId) {
    return Uri.parse("$api/catalog/subsections").replace(
      queryParameters: {'serviceId': serviceId},
    );
  }
  static Uri catalogAddonsUri(String serviceId) {
    return Uri.parse("$api/catalog/addons").replace(
      queryParameters: {'serviceId': serviceId},
    );
  }
  static String get serviceAreas => "$api/providers/me/service-areas";
  static String get acceptingJobs => "$api/providers/me/accepting-jobs";
  static String publicProfile(String providerUserId) =>
      "$api/providers/public/$providerUserId";
  static String get providerPayout => "$api/providers/me/payout";

  /// GET – combined earnings (summary + performance + recent transactions)
  static Uri earningsUri({int? transactionsLimit, int page = 1, int limit = 20}) {
    final params = <String, String>{
      if (transactionsLimit != null) 'transactionsLimit': transactionsLimit.toString(),
      'page': page.toString(),
      'limit': limit.toString(),
    };
    return Uri.parse('$api/providers/me/earnings').replace(queryParameters: params.isEmpty ? null : params);
  }
  static String get earningsSummary => "$api/providers/me/earnings/summary";
  static String get earningsPerformance => "$api/providers/me/earnings/performance";
  static Uri earningsTransactionsUri({int page = 1, int limit = 20}) =>
      Uri.parse('$api/providers/me/earnings/transactions').replace(queryParameters: {'page': page.toString(), 'limit': limit.toString()});

  /// POST body: townId, serviceId, subsectionId (List<String>), addonIds (List<String>), scheduledAtISO.
  static String get providerSearch => "$api/bookings/providers/search";

  // Towns
  static String get allTowns => "$api/towns/all";
  static String get createTown => "$api/towns";
  static String updateTown(String townId) => "$api/towns/$townId";

  /// Provider cabinet queue (assigned requests only — backend filters).
  static String get cabinetRequests => "$api/cabinet-requests";
  static String cabinetRequestById(String id) => "$api/cabinet-requests/$id";
  static String cabinetReviewStatus(String id) =>
      "$api/cabinet-requests/$id/review-status";
  static String cabinetQuote(String id) => "$api/cabinet-requests/$id/quote";
}

