/// Models for GET /customer/home?townId=...
/// Response shape:
/// {
///   "status": "success",
///   "message": "Home data fetched",
///   "data": {
///     "user": { "fullName": "John Doe" },
///     "town": { "_id": "...", "name": "Chitagoan" },
///     "topRatedProviders": [ ... ],
///     "servicesAvailable": [ ... ]
///   }
/// }
library;

class CustomerHomeResponse {
  final String status;
  final String message;
  final CustomerHomeData data;

  const CustomerHomeResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CustomerHomeResponse.fromJson(Map<String, dynamic> json) {
    return CustomerHomeResponse(
      status: _s(json['status']),
      message: _s(json['message']),
      data: json['data'] is Map<String, dynamic>
          ? CustomerHomeData.fromJson(json['data'] as Map<String, dynamic>)
          : CustomerHomeData.empty,
    );
  }
}

class CustomerHomeData {
  final HomeUser user;
  final HomeTown town;
  final List<ProviderCardModel> topRatedProviders;
  final List<ServiceModel> servicesAvailable;

  const CustomerHomeData({
    required this.user,
    required this.town,
    required this.topRatedProviders,
    required this.servicesAvailable,
  });

  static const empty = CustomerHomeData(
    user: HomeUser(fullName: ''),
    town: HomeTown(id: '', name: ''),
    topRatedProviders: [],
    servicesAvailable: [],
  );

  factory CustomerHomeData.fromJson(Map<String, dynamic> json) {
    return CustomerHomeData(
      user: json['user'] is Map<String, dynamic>
          ? HomeUser.fromJson(json['user'] as Map<String, dynamic>)
          : const HomeUser(fullName: ''),
      town: json['town'] is Map<String, dynamic>
          ? HomeTown.fromJson(json['town'] as Map<String, dynamic>)
          : const HomeTown(id: '', name: ''),
      topRatedProviders: _safeList(
        json['topRatedProviders'],
        ProviderCardModel.fromJson,
      ),
      servicesAvailable: _safeList(
        json['servicesAvailable'],
        ServiceModel.fromJson,
      ),
    );
  }
}

class HomeUser {
  final String fullName;

  const HomeUser({required this.fullName});

  factory HomeUser.fromJson(Map<String, dynamic> json) {
    return HomeUser(fullName: _s(json['fullName']));
  }
}

class HomeTown {
  final String id;
  final String name;

  const HomeTown({required this.id, required this.name});

  factory HomeTown.fromJson(Map<String, dynamic> json) {
    final id = _s(json['_id']).isNotEmpty ? _s(json['_id']) : _s(json['id']);
    return HomeTown(id: id, name: _s(json['name']));
  }
}

// ── Provider card model (from topRatedProviders) ─────────────────────────────

class ProviderCardModel {
  final String id;
  final String name;
  final String imageUrl;
  final double avgRating;
  final int reviewsCount;

  const ProviderCardModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.avgRating,
    required this.reviewsCount,
  });

  factory ProviderCardModel.fromJson(Map<String, dynamic> json) {
    final id = _s(json['_id']).isNotEmpty ? _s(json['_id']) : _s(json['id']);

    // name fallback: name → fullName → businessName
    final name = _s(json['name']).isNotEmpty
        ? _s(json['name'])
        : _s(json['fullName']).isNotEmpty
            ? _s(json['fullName'])
            : _s(json['businessName']);

    // image fallback: imageUrl → avatar → avatarUrl → profileImage
    final imageUrl = _s(json['imageUrl']).isNotEmpty
        ? _s(json['imageUrl'])
        : _s(json['avatar']).isNotEmpty
            ? _s(json['avatar'])
            : _s(json['avatarUrl']).isNotEmpty
                ? _s(json['avatarUrl'])
                : _s(json['profileImage']);

    return ProviderCardModel(
      id: id,
      name: name,
      imageUrl: imageUrl,
      avgRating: _asDouble(json['avgRating'] ?? json['rating'], 0.0),
      reviewsCount: _asInt(json['reviewsCount'] ?? json['reviewCount'] ?? json['reviews'], 0),
    );
  }
}

// ── Service model (from servicesAvailable) ───────────────────────────────────

class ServiceModel {
  final String id;
  final String name;
  final String icon;
  final String description;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final id = _s(json['_id']).isNotEmpty ? _s(json['_id']) : _s(json['id']);
    return ServiceModel(
      id: id,
      name: _s(json['name']),
      icon: _s(json['icon']).isNotEmpty ? _s(json['icon']) : _s(json['image']),
      description: _s(json['description']),
    );
  }
}

// ── helpers ──────────────────────────────────────────────────────────────────

String _s(dynamic v) => (v == null) ? '' : v.toString();

int _asInt(dynamic v, int fallback) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic v, double fallback) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? fallback;
}

List<T> _safeList<T>(dynamic v, T Function(Map<String, dynamic>) parser) {
  if (v is! List) return [];
  return v
      .whereType<Map>()
      .map((e) => parser(e.cast<String, dynamic>()))
      .toList();
}
