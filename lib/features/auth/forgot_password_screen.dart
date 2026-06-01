import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/gradient_background.dart';
import 'auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthState>();
    final ok = await auth.forgotPassword(_emailController.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() => _sent = true);
    } else {
      AppToast.error(context, auth.error ?? 'Something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Reset password')),
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
                      child: AnimatedSwitcher(
                        duration: AppMotion.base,
                        switchInCurve: AppMotion.standard,
                        child: _sent
                            ? _SentCard(
                                key: const ValueKey('sent'),
                                onBack: () => Navigator.of(context).pop(),
                              )
                            : _buildForm(auth),
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

  Widget _buildForm(AuthState auth) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_reset_outlined, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Forgot your password?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter your email and we’ll send you a reset link.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _submit(),
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
          const SizedBox(height: AppSpacing.xl),
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
                : const Text('Send reset link'),
          ),
        ],
      ),
    );
  }
}

class _SentCard extends StatelessWidget {
  const _SentCard({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
              child: Icon(Icons.mark_email_read_outlined,
                  size: 36, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Check your inbox',
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'If that email is registered, a reset link is on its way.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onBack,
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Back to login'),
            ),
          ],
        ),
      ),
    );
  }
}
