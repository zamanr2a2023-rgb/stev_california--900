/// Row from `GET /cabinet-requests` (provider assigned queue).
class ProviderCabinetListItem {
  const ProviderCabinetListItem({
    required this.id,
    required this.status,
    this.createdAt,
    this.customerName,
    this.townName,
    this.serviceName,
    this.photoCount = 0,
    this.quoteAmountCents,
    this.quoteCurrency,
  });

  final String id;
  final String status;
  final String? createdAt;
  final String? customerName;
  final String? townName;
  final String? serviceName;
  final int photoCount;
  final int? quoteAmountCents;
  final String? quoteCurrency;

  static String _s(dynamic v) => (v ?? '').toString();

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.cast<String, dynamic>();
    return null;
  }

  factory ProviderCabinetListItem.fromJson(Map<String, dynamic> json) {
    final id = _s(json['_id']).isNotEmpty ? _s(json['_id']) : _s(json['id']);

    int photoCount = 0;
    final ph = json['photos'];
    if (ph is List) photoCount = ph.length;

    int? quoteCents;
    String? quoteCur;
    final q = _asMap(json['quote']);
    if (q != null) {
      final c = q['amountCents'];
      quoteCents = c is int ? c : int.tryParse(c?.toString() ?? '');
      quoteCur = _s(q['currency']).isNotEmpty ? _s(q['currency']) : 'CAD';
    }

    String? customerName;
    if (_s(json['customerName']).isNotEmpty) {
      customerName = _s(json['customerName']);
    } else {
      final cust = _asMap(json['customer']);
      if (cust != null) {
        final a = _s(cust['fullName']);
        final b = _s(cust['name']);
        customerName = a.isNotEmpty ? a : (b.isNotEmpty ? b : null);
      }
    }

    String? serviceName;
    if (_s(json['serviceName']).isNotEmpty) {
      serviceName = _s(json['serviceName']);
    } else {
      final svc = _asMap(json['service']);
      if (svc != null) {
        final n = _s(svc['name']);
        serviceName = n.isNotEmpty ? n : null;
      }
    }

    String? townName;
    if (_s(json['townName']).isNotEmpty) {
      townName = _s(json['townName']);
    } else {
      final t = _asMap(json['town']);
      if (t != null) {
        final n = _s(t['name']);
        townName = n.isNotEmpty ? n : null;
      }
      final va = _asMap(json['visitAddress']);
      if (townName == null && va != null) {
        final c = _s(va['city']);
        townName = c.isNotEmpty ? c : null;
      }
    }

    return ProviderCabinetListItem(
      id: id,
      status: _s(json['status']).isNotEmpty ? _s(json['status']) : 'unknown',
      createdAt: json['createdAt'] != null ? _s(json['createdAt']) : null,
      customerName: customerName,
      townName: townName,
      serviceName: serviceName,
      photoCount: photoCount,
      quoteAmountCents: quoteCents,
      quoteCurrency: quoteCur,
    );
  }
}

class ProviderCabinetListResult {
  const ProviderCabinetListResult({
    required this.items,
    this.page,
    this.total,
    this.hasMore = false,
  });

  final List<ProviderCabinetListItem> items;
  final int? page;
  final int? total;
  final bool hasMore;
}
