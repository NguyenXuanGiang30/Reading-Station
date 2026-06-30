/// RegisterScreen - Màn hình đăng ký
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).t('auth_agree_required')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  double _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 6) strength += 0.25;
    if (password.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.125;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.125;
    return strength;
  }

  Color _getStrengthColor(double strength) {
    if (strength < 0.25) return AppColors.error;
    if (strength < 0.5) return AppColors.warning;
    if (strength < 0.75) return AppColors.accent;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _getPasswordStrength(_passwordController.text);
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
        title: S.of(context).t('auth_register'),
        subtitle: S.of(context).t('auth_register_subtitle'),
        icon: Icons.workspace_premium_rounded,
        onBack: () => context.pop(),
        footer: Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                S.of(context).t('auth_has_account'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(S.of(context).t('auth_login')),
              ),
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameController,
                label: S.of(context).t('auth_fullname'),
                hint: S.of(context).t('auth_fullname_hint'),
                prefix: const Icon(Icons.person_outline_rounded),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  final result = Validators.combine([
                    Validators.required(value, fieldName: S.of(context).t('auth_fullname')),
                    Validators.minLength(value, 2, fieldName: S.of(context).t('auth_fullname')),
                    Validators.maxLength(value, 100, fieldName: S.of(context).t('auth_fullname')),
                  ]);
                  return result.isValid ? null : result.errorMessage;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
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
                hint: S.of(context).t('auth_password_create'),
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
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final result = Validators.strongPassword(value);
                  return result.isValid ? null : result.errorMessage;
                },
              ),
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: strength,
                    minHeight: 6,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      _getStrengthColor(strength),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              CustomTextField(
                controller: _confirmPasswordController,
                label: S.of(context).t('auth_confirm_password'),
                hint: S.of(context).t('auth_confirm_hint'),
                obscureText: _obscureConfirmPassword,
                prefix: const Icon(Icons.lock_outline_rounded),
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
                validator: (value) {
                  final result = Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  );
                  return result.isValid ? null : result.errorMessage;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              CheckboxListTile(
                value: _agreeTerms,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primary,
                title: Text(
                  S.of(context).t('auth_agree_terms'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onChanged: (value) =>
                    setState(() => _agreeTerms = value ?? false),
              ),
              const SizedBox(height: AppSpacing.xl),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return PrimaryButton(
                    label: S.of(context).t('register_welcome'),
                    onPressed: _register,
                    loading: state is AuthLoading,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
