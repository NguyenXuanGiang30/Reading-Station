/// OtpVerificationScreen - Nhập mã OTP để xác thực
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/auth_scaffold.dart';
import '../../widgets/common/primary_button.dart';
import '../../l10n/app_localizations.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;

  String get _otp => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).t('auth_agree_required')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      await api.post(
        '/auth/verify-otp',
        data: {'email': widget.email, 'otp': _otp},
      );

      if (!mounted) return;
      context.pushReplacement(
        '/auth/reset-password',
        extra: {'email': widget.email, 'otp': _otp},
      );
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

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    try {
      final api = ApiService();
      await api.post('/auth/forgot-password', data: {'email': widget.email});
      for (final controller in _controllers) {
        controller.clear();
      }
      if (!mounted) return;
      _focusNodes.first.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).t('auth_otp_sent')),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.of(context).t("error")}: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: S.of(context).t('auth_otp_title'),
      subtitle: '${S.of(context).t('auth_otp_subtitle')} ${widget.email}.',
      icon: Icons.mark_email_read_outlined,
      onBack: () => context.pop(),
      footer: Center(
        child: TextButton(
          onPressed: _isResending ? null : _resendOtp,
          child: _isResending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(S.of(context).t('auth_resend')),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 48,
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: ''),
                  style: Theme.of(context).textTheme.headlineMedium,
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                    if (_otp.length == 6) {
                      _verifyOtp();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(
            label: S.of(context).t('auth_verify'),
            onPressed: _verifyOtp,
            loading: _isLoading,
          ),
        ],
      ),
    );
  }
}
