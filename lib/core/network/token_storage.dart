import 'package:expensetracker/data/models/auth_response_model.dart';

abstract class TokenStorage {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveTokens(AuthResponseModel response);
  Future<void> clearTokens();
}

class InMemoryTokenStorage implements TokenStorage {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> saveTokens(AuthResponseModel response) async {
    _accessToken = response.accessToken;
    _refreshToken = response.refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
