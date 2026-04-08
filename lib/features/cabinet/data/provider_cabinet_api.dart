import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/provider_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/cabinet/data/cabinet_requests_api.dart';
import 'package:renizo/features/cabinet/models/cabinet_request_detail_model.dart';
import 'package:renizo/features/cabinet/models/provider_cabinet_list_item.dart';

String? _messageFromBody(dynamic decoded) {
  if (decoded is Map) {
    return decoded['message']?.toString() ??
        decoded['error']?.toString() ??
        decoded['msg']?.toString();
  }
  return null;
}

/// `GET /cabinet-requests` — provider assigned queue.
Future<ProviderCabinetListResult> fetchProviderCabinetRequests({
  String? status,
  int page = 1,
  int limit = 20,
}) async {
  final token = await AuthLocalStorage.getToken();
  if (token == null || token.isEmpty) {
    throw Exception('Not signed in');
  }
  final uri = Uri.parse(ProviderApi.cabinetRequests).replace(
    queryParameters: <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
    },
  );
  final res = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );
  dynamic decoded;
  try {
    decoded = jsonDecode(res.body);
  } catch (_) {
    throw Exception('Invalid response from server');
  }
  if (res.statusCode >= 400) {
    throw Exception(_messageFromBody(decoded) ?? 'Failed to load cabinet requests');
  }
  if (decoded is! Map<String, dynamic>) {
    throw Exception('Unexpected response format');
  }

  List<Map<String, dynamic>> rawList = [];
  int? total;
  int? pageOut;
  bool hasMore = false;

  final data = decoded['data'];
  if (data is List) {
    rawList = data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  } else if (data is Map<String, dynamic>) {
    final list = data['items'] ?? data['requests'] ?? data['cabinetRequests'];
    if (list is List) {
      rawList = list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    final t = data['total'] ?? data['totalCount'];
    if (t is int) total = t;
    if (t is num) total = t.toInt();
    final p = data['page'];
    if (p is int) pageOut = p;
    if (p is num) pageOut = p.toInt();
    final hm = data['hasMore'] ?? data['hasNext'];
    if (hm is bool) hasMore = hm;
  }

  final items = rawList.map(ProviderCabinetListItem.fromJson).toList();

  if (total != null && pageOut != null) {
    final loaded = pageOut * limit;
    hasMore = loaded < total;
  }

  return ProviderCabinetListResult(
    items: items,
    page: pageOut ?? page,
    total: total,
    hasMore: hasMore,
  );
}

/// Same detail model as customer `GET /cabinet-requests/:id`.
Future<CabinetRequestDetail> fetchProviderCabinetDetail(String id) async {
  return fetchCabinetRequestDetail(id);
}

Future<void> patchCabinetReviewStatus({
  required String requestId,
  required String status,
  String? visitNotes,
  String? reason,
}) async {
  final token = await AuthLocalStorage.getToken();
  if (token == null || token.isEmpty) {
    throw Exception('Not signed in');
  }
  final body = <String, dynamic>{'status': status};
  if (visitNotes != null && visitNotes.trim().isNotEmpty) {
    body['visitNotes'] = visitNotes.trim();
  }
  if (reason != null && reason.trim().isNotEmpty) {
    body['reason'] = reason.trim();
  }
  final res = await http.patch(
    Uri.parse(ProviderApi.cabinetReviewStatus(requestId)),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode(body),
  );
  dynamic decoded;
  try {
    decoded = jsonDecode(res.body);
  } catch (_) {
    if (res.statusCode >= 400) {
      throw Exception('Request failed (${res.statusCode})');
    }
    return;
  }
  if (res.statusCode >= 400) {
    throw Exception(_messageFromBody(decoded) ?? 'Could not update status');
  }
}

/// `PATCH /cabinet-requests/:id/quote` — [amountCents] in minor units (e.g. 850000 for $8,500.00).
Future<void> patchCabinetQuote({
  required String requestId,
  required int amountCents,
  required String currency,
  String? scopeNote,
  String? visitNotes,
}) async {
  final token = await AuthLocalStorage.getToken();
  if (token == null || token.isEmpty) {
    throw Exception('Not signed in');
  }
  final body = <String, dynamic>{
    'amountCents': amountCents,
    'currency': currency.trim().isNotEmpty ? currency.trim() : 'CAD',
    if (scopeNote != null && scopeNote.trim().isNotEmpty)
      'scopeNote': scopeNote.trim(),
    if (visitNotes != null && visitNotes.trim().isNotEmpty)
      'visitNotes': visitNotes.trim(),
  };
  final res = await http.patch(
    Uri.parse(ProviderApi.cabinetQuote(requestId)),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode(body),
  );
  dynamic decoded;
  try {
    decoded = jsonDecode(res.body);
  } catch (_) {
    if (res.statusCode >= 400) {
      throw Exception('Request failed (${res.statusCode})');
    }
    return;
  }
  if (res.statusCode >= 400) {
    throw Exception(_messageFromBody(decoded) ?? 'Could not send quote');
  }
}
