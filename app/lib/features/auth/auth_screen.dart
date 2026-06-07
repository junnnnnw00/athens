import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../api/supabase.dart';
import '../../i18n.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = context.t('auth_enter_email_password', ref: ref));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = context.t('auth_enter_email_password', ref: ref));
      return;
    }
    if (password.length < 6) {
      setState(() => _error = context.t('auth_password_min_length', ref: ref));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: supabaseAuthRedirectUrl,
      );
      if (!mounted) return;
      if (res.session != null) {
        // Auto-confirmed: signed in immediately.
        context.go('/home');
      } else {
        // Email-confirmation mode is on for this project.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('auth_email_sent', ref: ref))),
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Athens')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.t('auth_login', ref: ref), style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            if (!isSupabaseInitialized) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.t('auth_supabase_missing', ref: ref),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: context.t('auth_email', ref: ref)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: context.t('auth_password', ref: ref)),
              obscureText: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: (_isLoading || !isSupabaseInitialized) ? null : _signIn,
              child: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.t('auth_login', ref: ref)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: (_isLoading || !isSupabaseInitialized) ? null : _signUp,
              child: Text(context.t('auth_signup', ref: ref)),
            ),
          ],
        ),
      ),
    );
  }
}
