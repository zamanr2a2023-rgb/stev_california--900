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
    this.customerName,
    this.serviceName,
    this.townName,
    this.visitAddressLine1,
    this.visitAddressLine2,
    this.city,
    this.postalCode,
    this.visitNotes,
    this.selectedAddons = const [],
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
  /// Provider list/detail when API includes customer display name.
  final String? customerName;
  final String? serviceName;
  final String? townName;
  final String? visitAddressLine1;
  final String? visitAddressLine2;
  final String? city;
  final String? postalCode;
  /// Site-visit / workflow notes from provider (distinct from customer [notes]).
  final String? visitNotes;
  final List<String> selectedAddons;
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

    List<String> addons = const [];
    final ad = json['selectedAddons'];
    if (ad is List) {
      addons = ad.map((e) => _s(e)).where((e) => e.isNotEmpty).toList();
    }

    String? customerName;
    final cn = json['customerName'];
    if (cn != null && _s(cn).isNotEmpty) {
      customerName = _s(cn);
    } else {
      final cust = _asMap(json['customer']);
      if (cust != null) {
        final a = _s(cust['fullName']);
        final b = _s(cust['name']);
        customerName = a.isNotEmpty ? a : (b.isNotEmpty ? b : null);
      }
    }

    String? serviceName;
    final sn = json['serviceName'];
    if (sn != null && _s(sn).isNotEmpty) {
      serviceName = _s(sn);
    } else {
      final svc = _asMap(json['service']);
      if (svc != null) {
        final n = _s(svc['name']);
        serviceName = n.isNotEmpty ? n : null;
      }
    }

    String? townName;
    final tn = json['townName'];
    if (tn != null && _s(tn).isNotEmpty) {
      townName = _s(tn);
    } else {
      final t = _asMap(json['town']);
      if (t != null) {
        final n = _s(t['name']);
        townName = n.isNotEmpty ? n : null;
      }
    }

    String? bookingId = _s(json['bookingId']);
    if (bookingId.isEmpty) {
      final b = _asMap(json['booking']);
      if (b != null) {
        bookingId = _s(b['_id']).isNotEmpty ? _s(b['_id']) : _s(b['id']);
      }
    }
    if (bookingId.isEmpty) bookingId = null;

    final visitNotesRaw = json['visitNotes'];
    final visitNotes =
        visitNotesRaw != null && _s(visitNotesRaw).isNotEmpty
            ? _s(visitNotesRaw)
            : null;

    return CabinetRequestDetail(
      id: id,
      status: _s(json['status']).isNotEmpty ? _s(json['status']) : 'unknown',
      timeline: json['timeline'] != null ? _s(json['timeline']) : null,
      style: json['style'] != null ? _s(json['style']) : null,
      notes: json['notes'] != null ? _s(json['notes']) : null,
      customerPhone:
          json['customerPhone'] != null ? _s(json['customerPhone']) : null,
      customerName: customerName,
      serviceName: serviceName,
      townName: townName,
      visitAddressLine1: visit != null ? _s(visit['line1']) : null,
      visitAddressLine2: visit != null ? _s(visit['line2']) : null,
      city: visit != null ? _s(visit['city']) : null,
      postalCode: visit != null ? _s(visit['postalCode']) : null,
      visitNotes: visitNotes,
      selectedAddons: addons,
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
