import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;
  String? _info;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    final email = _emailController.text;
    final password = _passwordController.text;
    final message = _isSignUp
        ? await _auth.signUpWithEmail(email, password)
        : await _auth.signInWithEmail(email, password);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = message;
    });
  }

  Future<void> _google() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    final message = await _auth.signInWithGoogle();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = message;
    });
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = 'Enter your email above first, then tap "Forgot password?".';
        _info = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    final message = await _auth.sendPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = message;
      if (message == null) _info = 'Password reset email sent to $email.';
    });
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _error = null;
      _info = null;
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book,
                        size: 80, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('Book Details App',
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(_isSignUp ? 'Create your account' : 'Sign in to continue', textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Enter your email';
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField( controller: _passwordController, obscureText: _hidePassword, textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _loading ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter your password';
                        if (_isSignUp && v.length < 6) {
                          return 'Use at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight, child: TextButton(
                          onPressed: _loading ? null : _forgotPassword, child: const Text('Forgot password?'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity, child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading ? const SizedBox(
                                width: 18,  height: 18, child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isSignUp ? 'Create account' : 'Sign in'),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                        textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    if (_info != null) ...[
                      const SizedBox(height: 12),  Text(_info!, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading ? null : _toggleMode,
                      child: Text(_isSignUp  ? 'Already have an account? Sign in' : 'New here? Create an account'),
                    ),
                    const Row(
                      children: [
                        Expanded(child: Divider()),Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, child: OutlinedButton.icon(
                        onPressed: _loading ? null : _google,
                        icon: const Icon(Icons.login),
                        label: const Text('Continue with Google',overflow: TextOverflow.ellipsis, ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}