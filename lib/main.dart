import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/network/dio_client.dart';
import 'core/network/session_manager.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/services/auth_service.dart';
import 'data/services/category_service.dart';
import 'data/services/report_service.dart';
import 'data/services/transaction_service.dart';
import 'logic/providers/auth_provider.dart';
import 'logic/providers/transaction_provider.dart';
import 'ui/home.dart';
import 'ui/screens/Log_in_screen.dart';

// Harden app startup so release-only initialization failures don't hang on the
// splash screen. Logs uncaught errors (visible in adb logcat) and ensures
// runApp is always reached even if provider init fails.
void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Report framework errors to the current zone so they show up in logs.
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        Zone.current.handleUncaughtError(
          details.exception,
          details.stack ?? StackTrace.current,
        );
      };
      await Hive.initFlutter();
      final sessionStorage = await HiveSessionStorage.open();
      final sessionManager = SessionManager(storage: sessionStorage);
      late final AuthService authService;
      final dioClient = DioClient(
        sessionManager: sessionManager,
        refreshTokenCallback: (_) async => authService.refreshToken(),
      );
      authService = AuthService(
        dio: dioClient.dio,
        sessionManager: sessionManager,
      );
      final categoryService = CategoryService(dio: dioClient.dio);
      final reportService = ReportService(dio: dioClient.dio);
      final apiRepository = TransactionRepository(
        apiService: TransactionService(dio: dioClient.dio),
      );
      final transactionProvider = TransactionProvider(
        repository: apiRepository,
      );

      // Protect provider initialization with a timeout and fallback so the
      // splash screen does not hang indefinitely in release builds.
      try {
        await transactionProvider.init().timeout(const Duration(seconds: 10));
      } catch (e, st) {
        debugPrint('TransactionProvider.init() failed or timed out: $e\n$st');
        // Leave provider in a default/empty state so the app can continue.
      }

      runApp(
        MultiProvider(
          providers: [
            Provider<SessionManager>.value(value: sessionManager),
            Provider<AuthService>.value(value: authService),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(
                authService: authService,
                sessionManager: sessionManager,
              ),
            ),
            Provider<CategoryService>.value(value: categoryService),
            Provider<ReportService>.value(value: reportService),
            ChangeNotifierProvider<TransactionProvider>.value(
              value: transactionProvider,
            ),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      // Catches any uncaught async errors during startup — visible in release logs.
      debugPrint('Uncaught zone error during startup: $error\n$stack');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.initialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.isAuthenticated) {
          return const Home();
        }

        return const LoginScreen();
      },
    );
  }
}
