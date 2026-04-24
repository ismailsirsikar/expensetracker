import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

abstract class SessionStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clear();
}

class InMemorySessionStorage implements SessionStorage {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}

class HiveSessionStorage implements SessionStorage {
  HiveSessionStorage(this._box);

  static const String boxName = 'session_tokens';
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';

  final Box _box;

  static Future<HiveSessionStorage> open() async {
    final box = await Hive.openBox(boxName);
    return HiveSessionStorage(box);
  }

  @override
  Future<String?> readAccessToken() async {
    return _box.get(accessTokenKey) as String?;
  }

  @override
  Future<String?> readRefreshToken() async {
    return _box.get(refreshTokenKey) as String?;
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _box.put(accessTokenKey, accessToken);
    await _box.put(refreshTokenKey, refreshToken);
  }

  @override
  Future<void> clear() async {
    await _box.delete(accessTokenKey);
    await _box.delete(refreshTokenKey);
  }
}

class SessionManager {
  SessionManager({SessionStorage? storage}) : _storage = storage ?? InMemorySessionStorage();

  final SessionStorage _storage;
  String? _accessToken;
  String? _refreshToken;

  Future<void> setSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.clear();
  }

  Future<String?> getAccessToken() async {
    return _accessToken ??= await _storage.readAccessToken();
  }

  Future<String?> getRefreshToken() async {
    return _refreshToken ??= await _storage.readRefreshToken();
  }

  Future<bool> hasSession() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }
}
