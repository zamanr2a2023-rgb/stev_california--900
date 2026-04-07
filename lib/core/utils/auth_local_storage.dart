import 'package:renizo/core/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth session – aligned with React AuthService session.
class AuthLocalStorage {
  static const _keyToken = 'token';
  static const _keyEmail = 'email';
  static const _keyUserId = 'userId';
  static const _keyUserName = 'userName';
  static const _keyUserRole = 'userRole';
  static const _keyUserPhone = 'userPhone';
  static const _keyUserAvatar = 'userAvatar';
  static const _keyHasOnboarded = 'hasOnboarded_';
  static const _keySelectedTown = 'selectedTown_';
  static const _keyFcmToken = 'fcmToken';
  static const _keySyncedFcmToken = 'syncedFcmToken';

  static Future<SharedPreferences> get _pref async =>
      SharedPreferences.getInstance();

  static Future<void> saveSession({
    required String token,
    required String email,
    required String userId,
    required String name,
    required String role,
    required String phone,
  }) async {
    final p = await _pref;
    await p.setString(_keyToken, token);
    await p.setString(_keyEmail, email);
    await p.setString(_keyUserId, userId);
    await p.setString(_keyUserName, name);
    await p.setString(_keyUserRole, role);
    await p.setString(_keyUserPhone, phone);
  }

  static Future<void> clearSession() async {
    final p = await _pref;
    await p.remove(_keyToken);
    await p.remove(_keyEmail);
    await p.remove(_keyUserId);
    await p.remove(_keyUserName);
    await p.remove(_keyUserRole);
    await p.remove(_keyUserPhone);
    await p.remove(_keyUserAvatar);
    await clearFcmTokens();
  }

  static Future<String?> getToken() async {
    final p = await _pref;
    return p.getString(_keyToken);
  }

  static Future<String?> getEmail() async {
    final p = await _pref;
    return p.getString(_keyEmail);
  }

  static Future<User?> getCurrentUser() async {
    final p = await _pref;
    final id = p.getString(_keyUserId);
    final email = p.getString(_keyEmail);
    final name = p.getString(_keyUserName);
    final roleStr = p.getString(_keyUserRole);
    final phone = p.getString(_keyUserPhone);
    final avatar = p.getString(_keyUserAvatar);
    if (id == null || email == null || name == null || roleStr == null) {
      return null;
    }
    final role = roleStr == 'provider' ? UserRole.provider : UserRole.customer;
    return User(
      id: id,
      email: email,
      name: name,
      role: role,
      phone: phone ?? '',
      avatar: avatar,
      createdAt: '',
    );
  }

  /// Update profile (name, email, phone, avatar). Keeps token, userId, role.
  static Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? avatar,
  }) async {
    final p = await _pref;
    await p.setString(_keyUserName, name);
    await p.setString(_keyEmail, email);
    await p.setString(_keyUserPhone, phone);
    if (avatar != null) {
      await p.setString(_keyUserAvatar, avatar);
    } else {
      await p.remove(_keyUserAvatar);
    }
  }

  /// True after this user has completed onboarding on this device (first login only).
  static Future<bool> hasOnboarded(String userId) async {
    final p = await _pref;
    return p.getBool(_keyHasOnboarded + userId) ?? false;
  }

  /// Mark onboarding as done for this user on this device.
  static Future<void> setOnboarded(String userId) async {
    final p = await _pref;
    await p.setBool(_keyHasOnboarded + userId, true);
  }

  static Future<void> setSelectedTown(String userId, String townJson) async {
    final p = await _pref;
    await p.setString(_keySelectedTown + userId, townJson);
  }

  static Future<String?> getSelectedTown(String userId) async {
    final p = await _pref;
    return p.getString(_keySelectedTown + userId);
  }

  static Future<String?> getAccessToken() async {
    final p = await _pref;
    return p.getString(_keyToken);
  }

  static Future<Map<String, String>?> authHeaders() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return null;
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static Future<void> saveFcmToken(String token) async {
    final p = await _pref;
    await p.setString(_keyFcmToken, token);
  }

  static Future<String?> getFcmToken() async {
    final p = await _pref;
    return p.getString(_keyFcmToken);
  }

  static Future<void> markFcmTokenSynced(String token) async {
    final p = await _pref;
    await p.setString(_keySyncedFcmToken, token);
  }

  static Future<String?> getSyncedFcmToken() async {
    final p = await _pref;
    return p.getString(_keySyncedFcmToken);
  }

  static Future<void> clearFcmTokens() async {
    final p = await _pref;
    await p.remove(_keyFcmToken);
    await p.remove(_keySyncedFcmToken);
  }
}
