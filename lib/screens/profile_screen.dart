import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/paywall_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleSignIn(Future<dynamic> Function() signInMethod) async {
    setState(() => _isLoading = true);
    try {
      await signInMethod();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Anmeldung fehlgeschlagen: $e'),
          backgroundColor: AppColors.of(context).danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signOut();
      await FirebaseAuth.instance.signInAnonymously();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          final user = snapshot.data;
          final isAnonymous = user?.isAnonymous ?? true;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAccountCard(c, user, isAnonymous),
              const SizedBox(height: 16),
              _buildPremiumCard(c),
              const SizedBox(height: 24),
              if (isAnonymous) _buildSignInSection(c),
              if (!isAnonymous) _buildSignOutSection(c),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAccountCard(AppColors c, User? user, bool isAnonymous) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAnonymous ? Icons.person_outline_rounded : Icons.person_rounded,
              color: c.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAnonymous
                      ? 'Gast'
                      : (user?.displayName ?? user?.email ?? 'Angemeldet'),
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAnonymous
                      ? 'Nicht angemeldet'
                      : (user?.email ?? ''),
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRestore() async {
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    final ok = await appState.restorePremium();
    if (!mounted) return;
    setState(() => _isLoading = false);
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'Premium wiederhergestellt.' : 'Kein Kauf gefunden.'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _buildPremiumCard(AppColors c) {
    final appState = context.watch<AppState>();
    // During the soft-launch phase (monetization off) there is nothing to sell,
    // so the card only appears once monetization is live or the user is premium.
    if (!appState.monetizationEnabled && !appState.isPremium) {
      return const SizedBox.shrink();
    }

    if (appState.isPremium) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.primarySoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: c.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Premium aktiv – danke für deine Unterstützung!',
                  style: TextStyle(
                      color: c.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showPaywall(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.primary, const Color(0xFF177A50)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Premium freischalten',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Unbegrenzte Preisalarme, voller Verlauf, werbefrei.',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : _handleRestore,
          child: Text('Kauf wiederherstellen',
              style: TextStyle(color: c.textSecondary, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildSignInSection(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account verknüpfen',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Verknüpfe deinen Account um Daten geräteübergreifend zu speichern.',
          style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          _GoogleSignInButton(
            onPressed: () => _handleSignIn(_authService.signInWithGoogle),
          ),
          const SizedBox(height: 12),
          SignInWithAppleButton(
            onPressed: () => _handleSignIn(_authService.signInWithApple),
            style: SignInWithAppleButtonStyle.whiteOutlined,
            borderRadius: BorderRadius.circular(14),
            height: 52,
          ),
        ],
      ],
    );
  }

  Widget _buildSignOutSection(AppColors c) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleSignOut,
        style: OutlinedButton.styleFrom(
          foregroundColor: c.danger,
          side: BorderSide(color: c.danger.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: c.danger),
              )
            : const Text('Abmelden',
                style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
