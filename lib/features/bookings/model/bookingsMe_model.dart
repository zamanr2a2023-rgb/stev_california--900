class BookingsMeData {
  final List<BookingsMeItem> items;
  final BookingsMeMeta meta;

  const BookingsMeData({required this.items, required this.meta});

  factory BookingsMeData.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final metaJson = json['meta'];

    return BookingsMeData(
      items: (itemsJson is List)
          ? itemsJson
                .whereType<Map>()
                .map((e) => BookingsMeItem.fromJson(e.cast<String, dynamic>()))
                .toList()
          : <BookingsMeItem>[],
      meta: (metaJson is Map<String, dynamic>)
          ? BookingsMeMeta.fromJson(metaJson)
          : const BookingsMeMeta(total: 0, page: 1, limit: 20),
    );
  }
}

class BookingsMeMeta {
  final int total;
  final int page;
  final int limit;

  const BookingsMeMeta({
    required this.total,
    required this.page,
    required this.limit,
  });

  factory BookingsMeMeta.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    return BookingsMeMeta(
      total: asInt(json['total'], 0),
      page: asInt(json['page'], 1),
      limit: asInt(json['limit'], 20),
    );
  }
}

class BookingsMeItem {
  final String id;
  final String providerName;
  final String providerAvatar;
  final String categoryName;
  final String status;
  final String scheduledDate;
  final String scheduledTime;

  const BookingsMeItem({
    required this.id,
    required this.providerName,
    required this.providerAvatar,
    required this.categoryName,
    required this.status,
    required this.scheduledDate,
    required this.scheduledTime,
  });

  static String _s(dynamic v) => (v == null) ? '' : v.toString();

  /// Parse ISO 8601 scheduledAt into date and time strings for display.
  static (String date, String time) _parseScheduledAt(dynamic scheduledAt) {
    final s = _s(scheduledAt);
    if (s.isEmpty) return ('', '');
    try {
      final dt = DateTime.tryParse(s);
      if (dt == null) return ('', '');
      final date = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return (date, time);
    } catch (_) {
      return ('', '');
    }
  }

  factory BookingsMeItem.fromJson(Map<String, dynamic> json) {
    // id fallback
    final id = _s(json['_id']).isNotEmpty ? _s(json['_id']) : _s(json['id']);

    // provider: API has name, logoUrl (not avatar)
    final provider = json['provider'];
    final providerName = _s(json['providerName']).isNotEmpty
        ? _s(json['providerName'])
        : (provider is Map ? _s(provider['name']) : '');

    final providerAvatar = _s(json['providerAvatar']).isNotEmpty
        ? _s(json['providerAvatar'])
        : (provider is Map ? _s(provider['logoUrl']) : '');

    // category: API has "service" (name), not "category"
    final category = json['category'];
    final service = json['service'];
    final categoryName = _s(json['categoryName']).isNotEmpty
        ? _s(json['categoryName'])
        : (category is Map ? _s(category['name']) : (service is Map ? _s(service['name']) : ''));

    // scheduledAt (ISO) preferred; fallback to scheduledDate/scheduledTime
    final scheduledDateJson = json['scheduledDate'];
    final scheduledTimeJson = json['scheduledTime'];
    final scheduledAt = json['scheduledAt'];
    String scheduledDate;
    String scheduledTime;
    if (_s(scheduledDateJson).isNotEmpty && _s(scheduledTimeJson).isNotEmpty) {
      scheduledDate = _s(scheduledDateJson);
      scheduledTime = _s(scheduledTimeJson);
    } else {
      final parsed = _parseScheduledAt(scheduledAt);
      scheduledDate = parsed.$1;
      scheduledTime = parsed.$2;
    }

    // status: use statusDisplay for display if present (e.g. "Pending"), else status (e.g. "pending_payment")
    final statusRaw = _s(json['status']);
    final statusDisplay = _s(json['statusDisplay']);
    final status = statusDisplay.isNotEmpty ? statusDisplay : statusRaw;

    return BookingsMeItem(
      id: id,
      providerName: providerName,
      providerAvatar: providerAvatar,
      categoryName: categoryName,
      status: status,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
    );
  }
}
