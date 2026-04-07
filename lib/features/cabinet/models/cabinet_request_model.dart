/// Customer cabinet request summary from `GET /cabinet-requests/me`.
class CabinetRequestListItem {
  const CabinetRequestListItem({
    required this.id,
    required this.status,
    this.timeline,
    this.style,
    this.createdAt,
  });

  final String id;
  final String status;
  final String? timeline;
  final String? style;
  final String? createdAt;

  static String _s(dynamic v) => (v ?? '').toString();

  factory CabinetRequestListItem.fromJson(Map<String, dynamic> json) {
    final id = _s(json['_id']).isNotEmpty ? _s(json['_id']) : _s(json['id']);
    return CabinetRequestListItem(
      id: id,
      status: _s(json['status']).isNotEmpty ? _s(json['status']) : 'unknown',
      timeline: json['timeline'] != null ? _s(json['timeline']) : null,
      style: json['style'] != null ? _s(json['style']) : null,
      createdAt: json['createdAt'] != null ? _s(json['createdAt']) : null,
    );
  }
}
