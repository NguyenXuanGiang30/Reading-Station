/// LoginScreen - Màn hình đăng nhập
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/validators.dart';
import '../../widgets/common/auth_scaffold.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/primary_button.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: AuthScaffold(
        title: S.of(context).t('auth_login_welcome'),
        subtitle: S.of(context).t('auth_login_subtitle'),
        icon: Icons.auto_stories_rounded,
        footer: Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                S.of(context).t('auth_no_account'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                onPressed: () => context.push('/register'),
                child: Text(S.of(context).t('auth_register_now')),
              ),
            ],
          ),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 24 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  controller: _emailController,
                  label: S.of(context).t('auth_email'),
                  hint: 'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  prefix: const Icon(Icons.mail_outline_rounded),
                  validator: (value) {
                    final result = Validators.email(value);
                    return result.isValid ? null : result.errorMessage;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                CustomTextField(
                  controller: _passwordController,
                  label: S.of(context).t('auth_password'),
                  hint: S.of(context).t('auth_password_hint'),
                  obscureText: _obscurePassword,
                  prefix: const Icon(Icons.lock_outline_rounded),
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    final result = Validators.required(
                      value,
                      fieldName: S.of(context).t('auth_password'),
                    );
                    return result.isValid ? null : result.errorMessage;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(S.of(context).t('auth_forgot')),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return PrimaryButton(
                      label: S.of(context).t('auth_login'),
                      onPressed: _login,
                      loading: state is AuthLoading,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        S.of(context).t('auth_or'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                _SocialButton(
                  label: S.of(context).t('auth_google'),
                  accent: AppColors.primary,
                  avatarLabel: 'G',
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      const AuthGoogleLoginRequested(),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _SocialButton(
                  label: S.of(context).t('auth_facebook'),
                  accent: const Color(0xFF1877F2),
                  avatarLabel: 'f',
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      const AuthFacebookLoginRequested(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color accent;
  final String avatarLabel;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.accent,
    required this.avatarLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: accent.withValues(alpha: 0.14),
            child: Text(
              avatarLabel,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: accent),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(label),
        ],
      ),
    );
  }
}
