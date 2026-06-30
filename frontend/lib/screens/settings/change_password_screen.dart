/// ChangePasswordScreen - Doi mat khau
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/data/status_chip.dart';
import '../../l10n/app_localizations.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      await api.post(
        '/auth/change-password',
        data: {
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
          'confirmPassword': _confirmPasswordController.text,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.of(context).t('change_pw_success'))));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loi: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('change_pw_title'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(),
                const SizedBox(height: AppSpacing.xl),
                ModernCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: S.of(context).t('change_pw_info'),
                        subtitle:
                            S.of(context).t('change_pw_info_desc'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      CustomTextField(
                        controller: _currentPasswordController,
                        label: S.of(context).t('change_pw_current'),
                        obscureText: _obscureCurrent,
                        validator: (value) {
                          final result = Validators.required(
                            value,
                            fieldName: S.of(context).t('change_pw_current'),
                          );
                          return result.isValid ? null : result.errorMessage;
                        },
                        prefix: const Icon(Icons.lock_outline_rounded),
                        suffix: IconButton(
                          onPressed: () => setState(
                            () => _obscureCurrent = !_obscureCurrent,
                          ),
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomTextField(
                        controller: _newPasswordController,
                        label: S.of(context).t('change_pw_new'),
                        obscureText: _obscureNew,
                        validator: (value) {
                          final result = Validators.strongPassword(value);
                          return result.isValid ? null : result.errorMessage;
                        },
                        prefix: const Icon(Icons.password_rounded),
                        suffix: IconButton(
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: S.of(context).t('change_pw_confirm'),
                        obscureText: _obscureConfirm,
                        validator: (value) {
                          final result = Validators.confirmPassword(
                            value,
                            _newPasswordController.text,
                          );
                          return result.isValid ? null : result.errorMessage;
                        },
                        prefix: const Icon(Icons.verified_user_outlined),
                        suffix: IconButton(
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ModernCard(
                  padding: const EdgeInsets.all(20),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primarySoft.withValues(alpha: 0.65),
                      AppColors.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).t('change_pw_checklist'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          StatusChip(
                            label: S.of(context).t('change_pw_rule1'),
                            color: AppColors.primary,
                            icon: Icons.looks_6_rounded,
                          ),
                          StatusChip(
                            label: S.of(context).t('change_pw_rule2'),
                            color: AppColors.secondary,
                            icon: Icons.text_fields_rounded,
                          ),
                          StatusChip(
                            label: S.of(context).t('change_pw_rule3'),
                            color: AppColors.warning,
                            icon: Icons.shield_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                PrimaryButton(
                  label: S.of(context).t('change_pw_btn'),
                  loading: _isLoading,
                  icon: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: _changePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return ModernCard(
      gradient: AppGradients.warmHero,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.lock_person_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).t('change_pw_hero_title'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  S.of(context).t('change_pw_hero_desc'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
