import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:renizo/core/constants/api_control/user_api.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/cabinet/models/cabinet_request_detail_model.dart';
import 'package:renizo/features/cabinet/models/cabinet_request_model.dart';

List<Map<String, dynamic>> _extractListFromBody(Map<String, dynamic> body) {
  final data = body['data'];
  if (data is List) {
    return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
  if (data is Map) {
    final m = data.cast<String, dynamic>();
    final list = m['requests'] ?? m['items'] ?? m['cabinetRequests'];
    if (list is List) {
      return list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
  }
  return [];
}

Map<String, dynamic>? _unwrapDataMap(Map<String, dynamic> decoded) {
  final d = decoded['data'];
  if (d is Map<String, dynamic>) return d;
  if (d is Map) return d.cast<String, dynamic>();
  return null;
}

/// GET /cabinet-requests/:requestId
Future<CabinetRequestDetail> fetchCabinetRequestDetail(String requestId) async {
  final token = await AuthLocalStorage.getToken();
  if (token == null || token.isEmpty) {
    throw Exception('Not signed in');
  }
  final res = await http.get(
    Uri.parse(UserApi.cabinetRequestById(requestId)),
    headers: {'Authorization': 'Bearer $token'},
  );
  dynamic decoded;
  try {
    decoded = jsonDecode(res.body);
  } catch (_) {
    throw Exception('Invalid response from server');
  }
  if (res.statusCode >= 400) {
    final msg = decoded is Map<String, dynamic>
        ? decoded['message']?.toString()
        : null;
    throw Exception(msg ?? 'Failed to load cabinet request');
  }
  if (decoded is! Map<String, dynamic>) {
    throw Exception('Unexpected response format');
  }
  final raw = _unwrapDataMap(decoded);
  if (raw == null) {
    throw Exception('Unexpected response format');
  }
  return CabinetRequestDetail.fromJson(raw);
}

/// POST /cabinet-requests/:requestId/accept-quote
Future<void> acceptCabinetQuote({
  required String requestId,
  required String scheduledAtIsoUtc,
}) async {
  final token = await AuthLocalStorage.getToken();
  if (token == null || token.isEmpty) {
    throw Exception('Not signed in');
  }
  final res = await http.post(
    Uri.parse(UserApi.cabinetRequestAcceptQuote(requestId)),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'scheduledAt': scheduledAtIsoUtc}),
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
    final msg = decoded is Map<String, dynamic>
        ? decoded['message']?.toString()
        : null;
    throw Exception(msg ?? 'Could not accept quote');
  }
}

/// POST /cabinet-requests/:requestId/cancel
Future<void> cancelCabinetRequest({
  required String requestId,
  required String reason,
}) async {
  final token = await AuthLocalStorage.getToken();
  if (token == null || token.isEmpty) {
    throw Exception('Not signed in');
  }
  final res = await http.post(
    Uri.parse(UserApi.cabinetRequestCancel(requestId)),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'reason': reason}),
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
    final msg = decoded is Map<String, dynamic>
        ? decoded['message']?.toString()
        : null;
    throw Exception(msg ?? 'Could not cancel request');
  }
}

/// GET /cabinet-requests/me
Future<List<CabinetRequestListItem>> fetchMyCabinetRequests({
  String? status,
}) async {
  final token = await AuthLocalStorage.getToken();
  final uri = Uri.parse(UserApi.cabinetRequestsMe).replace(
    queryParameters: status != null && status.isNotEmpty
        ? {'status': status}
        : null,
  );
  final res = await http.get(
    uri,
    headers: {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    },
  );
  dynamic decoded;
  try {
    decoded = jsonDecode(res.body);
  } catch (_) {
    throw Exception('Invalid response from server');
  }
  if (res.statusCode >= 400) {
    final msg = decoded is Map<String, dynamic>
        ? decoded['message']?.toString()
        : null;
    throw Exception(msg ?? 'Failed to load cabinet requests');
  }
  if (decoded is! Map<String, dynamic>) {
    throw Exception('Unexpected response format');
  }
  final raw = _extractListFromBody(decoded);
  return raw.map(CabinetRequestListItem.fromJson).toList();
}

/// One image for `photos` multipart field (same key repeated, like Postman).
typedef CabinetPhotoPart = ({Uint8List bytes, String filename});

/// Server rejects non-image MIME types (e.g. `application/octet-stream`).
/// [MultipartFile.fromBytes] must set [contentType] or uploads fail with
/// "Only image uploads are allowed".
MediaType _mediaTypeForImageFilename(String filename) {
  final lower = filename.toLowerCase().trim();
  if (lower.endsWith('.png')) return MediaType('image', 'png');
  if (lower.endsWith('.gif')) return MediaType('image', 'gif');
  if (lower.endsWith('.webp')) return MediaType('image', 'webp');
  if (lower.endsWith('.bmp')) return MediaType('image', 'bmp');
  if (lower.endsWith('.heic')) return MediaType('image', 'heic');
  if (lower.endsWith('.heif')) return MediaType('image', 'heif');
  // .jpg / .jpeg / unknown — gallery & cameras usually JPEG
  return MediaType('image', 'jpeg');
}

String _ensureImageFilename(String name, int index) {
  final t = name.trim();
  if (t.isEmpty) return 'photo_$index.jpg';
  if (RegExp(r'\.(jpe?g|png|gif|webp|bmp|heic|heif)$', caseSensitive: false)
      .hasMatch(t)) {
    return t;
  }
  return '$t.jpg';
}

void _throwIfCabinetCreateBodyFailed(Map<String, dynamic> body, int httpStatus) {
  if (httpStatus >= 400) {
    final msg = body['message']?.toString() ??
        body['error']?.toString() ??
        body['msg']?.toString();
    throw Exception(msg ?? 'Request failed ($httpStatus)');
  }
  final st = body['status']?.toString().toLowerCase();
  if (st == 'error' || st == 'fail' || body['success'] == false) {
    final msg = body['message']?.toString() ??
        body['error']?.toString() ??
        'Request failed';
    throw Exception(msg);
  }
}

/// POST /cabinet-requests (multipart form-data — matches Postman).
///
/// Uses [MultipartFile.fromBytes] for photos so Android `content://` gallery
/// picks work (`fromPath` often fails on those URIs).
Future<void> createCabinetRequest({
  required String townId,
  required String serviceId,
  required String customerPhone,
  required String timeline,
  required String notes,
  required String style,
  required List<String> selectedAddonIds,
  required Map<String, String> visitAddress,
  List<CabinetPhotoPart> photos = const [],
}) async {
  final token = await AuthLocalStorage.getToken();
  if (token == null || token.isEmpty) {
    throw Exception('Not signed in');
  }
  if (photos.isEmpty || photos.length > 6) {
    throw Exception('photos must contain 1 to 6 items');
  }

  final uri = Uri.parse(UserApi.cabinetRequests);
  final request = http.MultipartRequest('POST', uri);
  request.headers['Authorization'] = 'Bearer $token';
  request.headers['Accept'] = 'application/json';

  request.fields['townId'] = townId;
  request.fields['serviceId'] = serviceId;
  request.fields['customerPhone'] = customerPhone;
  request.fields['timeline'] = timeline;
  request.fields['notes'] = notes;
  request.fields['style'] = style;
  request.fields['selectedAddons'] = jsonEncode(selectedAddonIds);
  request.fields['visitAddress'] = jsonEncode(visitAddress);

  for (var i = 0; i < photos.length; i++) {
    final p = photos[i];
    if (p.bytes.isEmpty) continue;
    final name = _ensureImageFilename(p.filename, i);
    final contentType = _mediaTypeForImageFilename(name);
    request.files.add(
      http.MultipartFile.fromBytes(
        'photos',
        p.bytes,
        filename: name,
        contentType: contentType,
      ),
    );
  }

  final streamed = await request.send();
  final res = await http.Response.fromStream(streamed);
  dynamic decoded;
  try {
    decoded = jsonDecode(res.body);
  } catch (_) {
    if (res.statusCode >= 400) {
      throw Exception('Request failed (${res.statusCode})');
    }
    if (res.body.trim().isNotEmpty) {
      throw Exception('Invalid response from server');
    }
    return;
  }
  if (decoded is! Map<String, dynamic>) {
    if (res.statusCode >= 400) {
      throw Exception('Request failed (${res.statusCode})');
    }
    return;
  }
  _throwIfCabinetCreateBodyFailed(decoded, res.statusCode);
}
