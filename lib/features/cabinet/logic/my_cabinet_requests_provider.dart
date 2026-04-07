import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:renizo/features/cabinet/data/cabinet_requests_api.dart';
import 'package:renizo/features/cabinet/models/cabinet_request_model.dart';

/// Loads signed-in customer's cabinet requests (`GET /cabinet-requests/me`).
final myCabinetRequestsProvider =
    FutureProvider.autoDispose<List<CabinetRequestListItem>>((ref) async {
  return fetchMyCabinetRequests();
});
