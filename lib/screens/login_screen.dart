import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleSignIn(Future<dynamic> Function() signInMethod) async {
    setState(() => _isLoading = true);
    try {
      await signInMethod();
      if (mounted) _goToMain();
    } catch (e) {
      if (mounted) {
        final c = AppColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Anmeldung fehlgeschlagen: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: c.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildHeader(c),
              const Spacer(flex: 3),
              _buildButtons(),
              const SizedBox(height: 16),
              _buildSkipButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors c) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: c.primarySoft,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(Icons.shopping_basket_rounded,
              size: 42, color: c.primary),
        ),
        const SizedBox(height: 24),
        Text(
          'Preisvergleich',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Finde die besten Preise\nbei allen Supermärkten.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        if (_isLoading)
          const CircularProgressIndicator(color: Colors.white)
        else ...[
          _GoogleSignInButton(
            onPressed: () => _handleSignIn(_authService.signInWithGoogle),
          ),
          const SizedBox(height: 12),
          SignInWithAppleButton(
            onPressed: () => _handleSignIn(_authService.signInWithApple),
            style: SignInWithAppleButtonStyle.white,
            borderRadius: BorderRadius.circular(14),
            height: 52,
          ),
        ],
      ],
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _isLoading
          ? null
          : () => _handleSignIn(_authService.continueAnonymously),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
      child: Text(
        'Ohne Account fortfahren',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.google.com/favicon.ico',
              width: 20,
              height: 20,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.g_mobiledata, size: 24),
            ),
            const SizedBox(width: 10),
            const Text(
              'Mit Google anmelden',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
