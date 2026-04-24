import 'package:flutter/foundation.dart';

import '../../core/network/session_manager.dart';
import '../../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required this.authService,
    required this.sessionManager,
  }) {
    _initializeAuthState();
  }

  final AuthService authService;
  final SessionManager sessionManager;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _initialized = false;
  bool get initialized => _initialized;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await authService.login(email: email, password: password);
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await authService.logout();
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> refreshAuthenticationStatus() async {
    _isAuthenticated = await sessionManager.hasSession();
    notifyListeners();
  }

  Future<void> _initializeAuthState() async {
    _isAuthenticated = await sessionManager.hasSession();
    _initialized = true;
    notifyListeners();
  }
}
