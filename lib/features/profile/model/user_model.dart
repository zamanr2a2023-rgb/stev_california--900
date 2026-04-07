import 'package:renizo/core/models/user.dart';

class UserMeModel {
  // profile
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String avatarUrl;
  final String roleRaw;

  // stats
  final int bookings;
  final int reviews;
  final int favorites;

  // town
  final String? townId;
  final String? townName;

  const UserMeModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.roleRaw,
    required this.bookings,
    required this.reviews,
    required this.favorites,
    this.townId,
    this.townName,
  });

  factory UserMeModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? {};
    final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
    final stats = (data['stats'] as Map<String, dynamic>?) ?? {};
    final town = data['town'] as Map<String, dynamic>?;

    int toInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    String toStr(dynamic v) => (v ?? '').toString();

    return UserMeModel(
      id: toStr(profile['_id']),
      fullName: toStr(profile['fullName']),
      email: toStr(profile['email']),
      phone: toStr(profile['phone']),
      avatarUrl: toStr(profile['avatarUrl']),
      roleRaw: toStr(profile['role']),
      bookings: toInt(stats['bookings']),
      reviews: toInt(stats['reviews']),
      favorites: toInt(stats['favorites']),
      townId: town == null ? null : toStr(town['_id']),
      townName: town == null ? null : toStr(town['name']),
    );
  }

  /// ✅ String role -> UserRole enum conversion (safe)
  UserRole parseUserRole() {
    final raw = roleRaw.trim().toLowerCase();

    // 1) direct enum name match
    for (final r in UserRole.values) {
      if (r.name.toLowerCase() == raw) return r;
    }

    // 2) alias: API "user" == app "customer"
    if (raw == 'user') {
      for (final r in UserRole.values) {
        if (r.name.toLowerCase() == 'customer') return r;
      }
    }

    // 3) fallback
    return UserRole.values.first;
  }

  /// আপনার ProfileScreen যেহেতু `User` model ইউজ করছে, তাই convert করে দিচ্ছি
  User toUser() {
    return User(
      id: id,
      name: fullName,
      email: email,
      phone: phone,
      avatar: avatarUrl.isEmpty ? null : avatarUrl,
      role: parseUserRole(),
      createdAt: '', // ✅ এখানে fix
    );
  }
}
