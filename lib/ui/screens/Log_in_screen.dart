import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../data/services/auth_service.dart';
import '../../logic/providers/transaction_provider.dart';
import '../home.dart';

// ── Shared design system (keep in sync with home.dart) ───────────────────────
class _DS {
  static const bg = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const card = Color(0xFF1C2128);
  static const border = Color(0xFF30363D);
  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const red = Color(0xFFF85149);
  static const blue = Color(0xFF58A6FF);
}

String _extractErrorMessage(Object error) {
  if (error is ApiException) {
    return error.message;
  }
  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiException) {
      return inner.message;
    }
    return error.message ?? 'An unexpected network error occurred.';
  }
  return error.toString();
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);

    try {
      await authService.login(email: email, password: password);
      await transactionProvider.reload();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
    } catch (error) {
      final message = _extractErrorMessage(error);
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.bg,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // ── Logo & brand ────────────────────────────────────────
                  Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4FC3F7).withOpacity(0.30),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ExpenseTracker',
                      style: TextStyle(
                        color: _DS.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 48),

                  // ── Heading ─────────────────────────────────────────────
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      color: _DS.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to continue tracking your finances.',
                    style: TextStyle(
                      color: _DS.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Form card ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: _DS.surface,
                      border: Border.all(color: _DS.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email
                        _FieldLabel(label: 'Email address'),
                        const SizedBox(height: 8),
                        _AuthTextField(
                          controller: _emailController,
                          hint: 'you@example.com',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),

                        // Password
                        _FieldLabel(label: 'Password'),
                        const SizedBox(height: 8),
                        _AuthTextField(
                          controller: _passwordController,
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscurePassword,
                          suffix: GestureDetector(
                            onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _DS.textSecondary,
                              size: 18,
                            ),
                          ),
                        ),

                        // Error message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          _ErrorBanner(message: _errorMessage!),
                        ],

                        const SizedBox(height: 24),

                        // Login button
                        _PrimaryButton(
                          label: 'Sign In',
                          loading: _loading,
                          onTap: _handleLogin,
                          gradient: const [
                            Color(0xFF0288D1),
                            Color(0xFF4FC3F7),
                          ],
                          glowColor: Color(0xFF4FC3F7),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Register link ───────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              color: _DS.textSecondary, fontSize: 13),
                          children: [
                            TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Create one',
                              style: TextStyle(
                                color: _DS.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    if (password.length < 8) {
      setState(
          () => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);

    try {
      await authService.register(
        name: name,
        email: email,
        password: password,
      );
      await transactionProvider.reload();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
    } catch (error) {
      final message = _extractErrorMessage(error);
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.bg,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // ── Logo & brand ────────────────────────────────────────
                  Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0288D1), Color(0xFF4FC3F7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4FC3F7).withOpacity(0.30),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ExpenseTracker',
                      style: TextStyle(
                        color: _DS.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 48),

                  // ── Heading ─────────────────────────────────────────────
                  const Text(
                    'Create account',
                    style: TextStyle(
                      color: _DS.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Start tracking your expenses in seconds.',
                    style: TextStyle(
                      color: _DS.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Form card ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: _DS.surface,
                      border: Border.all(color: _DS.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        _FieldLabel(label: 'Full name'),
                        const SizedBox(height: 8),
                        _AuthTextField(
                          controller: _nameController,
                          hint: 'Jane Doe',
                          icon: Icons.person_outline_rounded,
                          keyboardType: TextInputType.name,
                        ),

                        const SizedBox(height: 20),

                        // Email
                        _FieldLabel(label: 'Email address'),
                        const SizedBox(height: 8),
                        _AuthTextField(
                          controller: _emailController,
                          hint: 'you@example.com',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),

                        // Password
                        _FieldLabel(label: 'Password'),
                        const SizedBox(height: 8),
                        _AuthTextField(
                          controller: _passwordController,
                          hint: 'Minimum 8 characters',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscurePassword,
                          suffix: GestureDetector(
                            onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _DS.textSecondary,
                              size: 18,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Confirm password
                        _FieldLabel(label: 'Confirm password'),
                        const SizedBox(height: 8),
                        _AuthTextField(
                          controller: _confirmController,
                          hint: 'Re-enter your password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscureConfirm,
                          suffix: GestureDetector(
                            onTap: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            child: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _DS.textSecondary,
                              size: 18,
                            ),
                          ),
                        ),

                        // Error message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          _ErrorBanner(message: _errorMessage!),
                        ],

                        const SizedBox(height: 24),

                        // Register button
                        _PrimaryButton(
                          label: 'Create Account',
                          loading: _loading,
                          onTap: _handleRegister,
                          gradient: const [
                            Color(0xFF1B5E20),
                            Color(0xFF3FB950),
                          ],
                          glowColor: Color(0xFF3FB950),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Login link ──────────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              color: _DS.textSecondary, fontSize: 13),
                          children: [
                            TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign in',
                              style: TextStyle(
                                color: _DS.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _DS.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboardType;

  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _DS.card,
        border: Border.all(color: _DS.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: _DS.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _DS.textSecondary, fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, color: _DS.textSecondary, size: 18),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: suffix,
                )
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        cursorColor: _DS.blue,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _DS.red.withOpacity(0.10),
        border: Border.all(color: _DS.red.withOpacity(0.35)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: _DS.red, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
                color: _DS.red, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  final List<Color> gradient;
  final Color glowColor;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
    required this.gradient,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedOpacity(
        opacity: loading ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient:
                LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.30),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}