/// ForgotPasswordScreen - Nhập email để nhận OTP
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/validators.dart';
import '../../widgets/common/auth_scaffold.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/primary_button.dart';
import '../../l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      await api.post(
        '/auth/forgot-password',
        data: {'email': _emailController.text.trim()},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).t('auth_otp_sent')),
          backgroundColor: AppColors.success,
        ),
      );
      context.push('/auth/verify-otp', extra: _emailController.text.trim());
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
      title: S.of(context).t('auth_forgot'),
      subtitle: S.of(context).t('auth_forgot_subtitle'),
      icon: Icons.lock_reset_rounded,
      onBack: () => context.pop(),
      footer: Center(
        child: TextButton(
          onPressed: () => context.pop(),
          child: Text(S.of(context).t('auth_back_login')),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              controller: _emailController,
              label: S.of(context).t('auth_email'),
              hint: 'example@gmail.com',
              keyboardType: TextInputType.emailAddress,
              prefix: const Icon(Icons.email_outlined),
              validator: (value) {
                final result = Validators.email(value);
                return result.isValid ? null : result.errorMessage;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: S.of(context).t('auth_send_otp'),
              onPressed: _sendOtp,
              loading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
