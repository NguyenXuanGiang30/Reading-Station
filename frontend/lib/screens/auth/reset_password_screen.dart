/// ResetPasswordScreen - Đặt lại mật khẩu sau khi xác thực OTP
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/auth_scaffold.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/primary_button.dart';
import '../../l10n/app_localizations.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      await api.post(
        '/auth/reset-password',
        data: {
          'email': widget.email,
          'otp': widget.otp,
          'newPassword': _passwordController.text,
          'confirmPassword': _confirmPasswordController.text,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).t('auth_reset_title')),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.of(context).t("error")}: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: S.of(context).t('auth_reset_title'),
      subtitle: S.of(context).t('auth_reset_subtitle'),
      icon: Icons.lock_open_rounded,
      onBack: () => context.pop(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              controller: _passwordController,
              label: S.of(context).t('auth_new_password'),
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
                if (value == null || value.isEmpty) {
                  return S.of(context).t('reset_pw_required');
                }
                if (value.length < 6) {
                  return S.of(context).t('reset_pw_min_length');
                }
                if (!RegExp(r'[0-9]').hasMatch(value)) {
                  return S.of(context).t('reset_pw_need_number');
                }
                if (!RegExp(r'[A-Z]').hasMatch(value)) {
                  return S.of(context).t('reset_pw_need_upper');
                }
                if (!RegExp(
                  r'[!@#\$%^&*()_+\-=\[\]{};:"\\|,.<>/?`~]',
                ).hasMatch(value)) {
                  return S.of(context).t('reset_pw_need_special');
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomTextField(
              controller: _confirmPasswordController,
              label: S.of(context).t('auth_confirm_password'),
              hint: S.of(context).t('auth_confirm_hint'),
              obscureText: _obscureConfirm,
              prefix: const Icon(Icons.verified_user_outlined),
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).t('reset_confirm_required');
                }
                if (value != _passwordController.text) {
                  return S.of(context).t('reset_confirm_mismatch');
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: S.of(context).t('auth_reset_btn'),
              onPressed: _resetPassword,
              loading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
