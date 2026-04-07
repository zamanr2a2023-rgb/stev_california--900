/// Raw API response for GET /bookings/:id – matches backend JSON.
class BookingDetailApiModel {
  const BookingDetailApiModel({
    required this.id,
    required this.scheduledAt,
    required this.address,
    this.notes,
    required this.price,
    required this.status,
    required this.paymentStatus,
    this.providerName,
    this.providerLogoUrl,
    this.serviceName,
    this.townName,
    this.customerName,
    this.customerAvatarUrl,
  });

  final String id;
  final String scheduledAt;
  final BookingAddressApi address;
  final String? notes;
  final BookingPriceApi price;
  final String status;
  final String paymentStatus;
  final String? providerName;
  final String? providerLogoUrl;
  final String? serviceName;
  final String? townName;
  /// From provider booking API: customer.name, customer.avatarUrl
  final String? customerName;
  final String? customerAvatarUrl;

  static String _s(dynamic v) => (v == null) ? '' : v.toString();

  factory BookingDetailApiModel.fromJson(Map<String, dynamic> json) {
    final addressJson = json['address'];
    final priceJson = json['price'];
    final provider = json['provider'];
    final providerId = json['providerId'];
    final customer = json['customer'];
    final town = json['town'];
    final townId = json['townId'];
    final service = json['service'];
    final serviceId = json['serviceId'];

    // Provider: support both "provider" (name, logoUrl) and "providerId" (fullName, avatarUrl) when populated
    String? pName;
    if (provider is Map) {
      pName = _s(provider['name']).trim().isEmpty ? null : _s(provider['name']);
    }
    if (pName == null && providerId is Map) {
      final fn = _s(providerId['fullName']).trim();
      pName = fn.isEmpty ? null : fn;
    }
    String? pLogo;
    if (provider is Map) {
      pLogo = _s(provider['logoUrl']).trim().isEmpty ? null : _s(provider['logoUrl']);
    }
    if (pLogo == null && providerId is Map) {
      final av = _s(providerId['avatarUrl']).trim();
      pLogo = av.isEmpty ? null : av;
    }

    // Town: "town" or "townId" when populated with name
    String? tName;
    if (town is Map) tName = _s(town['name']).trim().isEmpty ? null : _s(town['name']);
    if (tName == null && townId is Map) tName = _s(townId['name']).trim().isEmpty ? null : _s(townId['name']);

    // Service: "service" or "serviceId" when populated with name
    String? sName;
    if (service is Map) sName = _s(service['name']).trim().isEmpty ? null : _s(service['name']);
    if (sName == null && serviceId is Map) sName = _s(serviceId['name']).trim().isEmpty ? null : _s(serviceId['name']);

    // Customer: from provider booking API
    String? cName;
    String? cAvatar;
    if (customer is Map) {
      cName = _s(customer['name']).trim().isEmpty ? null : _s(customer['name']);
      cAvatar = _s(customer['avatarUrl']).trim().isEmpty ? null : _s(customer['avatarUrl']);
    }

    return BookingDetailApiModel(
      id: _s(json['_id']).isEmpty ? _s(json['id']) : _s(json['_id']),
      scheduledAt: _s(json['scheduledAt']),
      address: addressJson is Map<String, dynamic>
          ? BookingAddressApi.fromJson(addressJson)
          : const BookingAddressApi(line1: '', line2: '', city: '', postalCode: ''),
      notes: _s(json['notes']).isEmpty ? null : _s(json['notes']),
      price: priceJson is Map<String, dynamic>
          ? BookingPriceApi.fromJson(priceJson)
          : const BookingPriceApi(currency: 'CAD', basePriceCents: 0, addonsTotalCents: 0, totalCents: 0, renizoFeePercent: 0, renizoFeeCents: 0, providerPayoutCents: 0),
      status: _s(json['status']),
      paymentStatus: _s(json['paymentStatus']),
      providerName: pName,
      providerLogoUrl: pLogo,
      serviceName: sName,
      townName: tName,
      customerName: cName,
      customerAvatarUrl: cAvatar,
    );
  }
}

class BookingAddressApi {
  const BookingAddressApi({
    required this.line1,
    required this.line2,
    required this.city,
    required this.postalCode,
  });

  final String line1;
  final String line2;
  final String city;
  final String postalCode;

  static String _s(dynamic v) => (v == null) ? '' : v.toString();

  factory BookingAddressApi.fromJson(Map<String, dynamic> json) {
    return BookingAddressApi(
      line1: _s(json['line1']),
      line2: _s(json['line2']),
      city: _s(json['city']),
      postalCode: _s(json['postalCode']),
    );
  }

  String get displayAddress {
    final parts = [line1, if (line2.isNotEmpty) line2, city, postalCode].where((e) => e.isNotEmpty).toList();
    return parts.join(', ');
  }
}

class BookingPriceApi {
  const BookingPriceApi({
    required this.currency,
    required this.basePriceCents,
    required this.addonsTotalCents,
    required this.totalCents,
    required this.renizoFeePercent,
    required this.renizoFeeCents,
    required this.providerPayoutCents,
  });

  final String currency;
  final int basePriceCents;
  final int addonsTotalCents;
  final int totalCents;
  final int renizoFeePercent;
  final int renizoFeeCents;
  final int providerPayoutCents;

  double get totalAmount => totalCents / 100.0;
  double get renizoFeeAmount => renizoFeeCents / 100.0;

  factory BookingPriceApi.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '0') ?? 0;
    }
    return BookingPriceApi(
      currency: (json['currency'] ?? 'CAD').toString(),
      basePriceCents: asInt(json['basePriceCents']),
      addonsTotalCents: asInt(json['addonsTotalCents']),
      totalCents: asInt(json['totalCents']),
      renizoFeePercent: asInt(json['renizoFeePercent']),
      renizoFeeCents: asInt(json['renizoFeeCents']),
      providerPayoutCents: asInt(json['providerPayoutCents']),
    );
  }
}
