import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/motion/page_transitions.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/gradient_background.dart';
import 'auth_state.dart';
import 'forgot_password_screen.dart';

/// Combined login / signup screen with an animated toggle.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthState>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final ok = _isLogin
        ? await auth.login(email, password)
        : await auth.signup(email, password, _nameController.text.trim());
    // On success the AuthGate swaps screens automatically; only surface failures.
    if (!ok && mounted) {
      AppToast.error(context, auth.error ?? 'Something went wrong');
    }
  }

  void _toggleMode() {
    if (context.read<AuthState>().loading) return;
    setState(() => _isLogin = !_isLogin);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final theme = Theme.of(context);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Image.asset(
                              'assets/images/aiva_logo.png',
                              height: 84,
                              semanticLabel: 'AIVA logo',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Center(
                              child: Image.asset(
                                'assets/images/aiva_text.png',
                                height: 52,
                                semanticLabel: 'AIVA',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            AnimatedSwitcher(
                              duration: AppMotion.base,
                              child: Text(
                                _isLogin ? 'Welcome back' : 'Create your account',
                                key: ValueKey(_isLogin),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _isLogin
                                  ? 'Log in to pick up where you left off.'
                                  : 'A few details and AIVA is yours.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: AppSpacing.xxl),

                            // Name field — present only in signup; animates in/out.
                            ClipRect(
                              child: AnimatedAlign(
                                alignment: Alignment.topCenter,
                                heightFactor: _isLogin ? 0 : 1,
                                duration: AppMotion.base,
                                curve: AppMotion.standard,
                                child: AnimatedOpacity(
                                  opacity: _isLogin ? 0 : 1,
                                  duration: AppMotion.base,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                                    child: TextFormField(
                                      controller: _nameController,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: 'Full name (optional)',
                                        prefixIcon: Icon(Icons.person_outline),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) return 'Email is required';
                                if (!value.contains('@')) return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscure ? 'Show password' : 'Hide password',
                                  icon: Icon(_obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) {
                                final value = v ?? '';
                                if (value.isEmpty) return 'Password is required';
                                if (!_isLogin && value.length < 8) {
                                  return 'At least 8 characters';
                                }
                                return null;
                              },
                            ),

                            if (_isLogin)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                    sharedAxisRoute<void>(
                                      (_) => const ForgotPasswordScreen(),
                                    ),
                                  ),
                                  child: const Text('Forgot password?'),
                                ),
                              )
                            else
                              const SizedBox(height: AppSpacing.xl),

                            const SizedBox(height: AppSpacing.sm),
                            FilledButton(
                              onPressed: auth.loading ? null : _submit,
                              style: FilledButton.styleFrom(
                                shape: const StadiumBorder(),
                                minimumSize: const Size.fromHeight(54),
                              ),
                              child: auth.loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.4),
                                    )
                                  : AnimatedSwitcher(
                                      duration: AppMotion.fast,
                                      child: Text(
                                        _isLogin ? 'Log in' : 'Sign up',
                                        key: ValueKey(_isLogin),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextButton(
                              onPressed: auth.loading ? null : _toggleMode,
                              child: Text(
                                _isLogin
                                    ? "Don't have an account?  Sign up"
                                    : 'Already have an account?  Log in',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
