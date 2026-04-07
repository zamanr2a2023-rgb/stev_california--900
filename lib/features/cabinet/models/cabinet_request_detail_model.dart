import 'dart:convert';

/// Full cabinet request from `GET /cabinet-requests/:requestId`.
class CabinetQuoteInfo {
  const CabinetQuoteInfo({
    required this.amountCents,
    required this.currency,
    this.scopeNote,
    this.visitNotes,
  });

  final int amountCents;
  final String currency;
  final String? scopeNote;
  final String? visitNotes;

  double get amountMajor => amountCents / 100.0;
}

class CabinetRequestDetail {
  const CabinetRequestDetail({
    required this.id,
    required this.status,
    this.timeline,
    this.style,
    this.notes,
    this.customerPhone,
    this.visitAddressLine1,
    this.visitAddressLine2,
    this.city,
    this.postalCode,
    this.quote,
    this.bookingId,
    this.photos = const [],
  });

  final String id;
  final String status;
  final String? timeline;
  final String? style;
  final String? notes;
  final String? customerPhone;
  final String? visitAddressLine1;
  final String? visitAddressLine2;
  final String? city;
  final String? postalCode;
  final CabinetQuoteInfo? quote;
  final String? bookingId;
  final List<String> photos;

  static String _s(dynamic v) => (v ?? '').toString();

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.cast<String, dynamic>();
    return null;
  }

  factory CabinetRequestDetail.fromJson(Map<String, dynamic> json) {
    final id = _s(json['_id']).isNotEmpty ? _s(json['_id']) : _s(json['id']);

    Map<String, dynamic>? visit = _asMap(json['visitAddress']);
    if (visit == null && json['visitAddress'] is String) {
      try {
        final decoded = jsonDecode(json['visitAddress'] as String);
        visit = _asMap(decoded);
      } catch (_) {}
    }
    if (visit == null && json['visit'] is Map) {
      visit = _asMap(json['visit']);
    }

    CabinetQuoteInfo? quote;
    final q = _asMap(json['quote']);
    if (q != null) {
      final cents = q['amountCents'];
      final c = cents is int
          ? cents
          : int.tryParse(cents?.toString() ?? '') ?? 0;
      quote = CabinetQuoteInfo(
        amountCents: c,
        currency: _s(q['currency']).isNotEmpty ? _s(q['currency']) : 'CAD',
        scopeNote: q['scopeNote'] != null ? _s(q['scopeNote']) : null,
        visitNotes: q['visitNotes'] != null ? _s(q['visitNotes']) : null,
      );
    }

    List<String> photos = const [];
    final ph = json['photos'];
    if (ph is List) {
      photos = ph.map((e) => _s(e)).where((e) => e.isNotEmpty).toList();
    }

    String? bookingId = _s(json['bookingId']);
    if (bookingId.isEmpty) {
      final b = _asMap(json['booking']);
      if (b != null) {
        bookingId = _s(b['_id']).isNotEmpty ? _s(b['_id']) : _s(b['id']);
      }
    }
    if (bookingId.isEmpty) bookingId = null;

    return CabinetRequestDetail(
      id: id,
      status: _s(json['status']).isNotEmpty ? _s(json['status']) : 'unknown',
      timeline: json['timeline'] != null ? _s(json['timeline']) : null,
      style: json['style'] != null ? _s(json['style']) : null,
      notes: json['notes'] != null ? _s(json['notes']) : null,
      customerPhone:
          json['customerPhone'] != null ? _s(json['customerPhone']) : null,
      visitAddressLine1: visit != null ? _s(visit['line1']) : null,
      visitAddressLine2: visit != null ? _s(visit['line2']) : null,
      city: visit != null ? _s(visit['city']) : null,
      postalCode: visit != null ? _s(visit['postalCode']) : null,
      quote: quote,
      bookingId: bookingId,
      photos: photos,
    );
  }

  bool get canCancel => !const {
    'converted',
    'cancelled',
    'rejected',
  }.contains(status);

  bool get canAcceptQuote => status == 'quoted';
}
