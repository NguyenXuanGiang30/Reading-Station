/// EditProfileScreen - Chỉnh sửa hồ sơ cá nhân
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../constants/app_constants.dart' show AppConstants;
import '../../services/user_service.dart';
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
import '../../l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  int _yearlyGoal = 24;
  bool _isBusy = false;
  bool _isSaving = false;
  String? _localAvatarPath; // Đường dẫn ảnh local khi chọn từ gallery

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _nameController.text = user.fullName;
      _bioController.text = user.bio ?? '';
      _emailController.text = user.email;
      _yearlyGoal = 24;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? avatarUrl;

      // Nếu có ảnh mới, upload trước
      if (_localAvatarPath != null) {
        avatarUrl = await _userService.uploadAvatar(_localAvatarPath!);
        if (avatarUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).t('edit_upload_failed'))),
          );
          setState(() => _isSaving = false);
          return;
        }
      }

      // Dispatch update qua AuthBloc (sẽ gọi API PUT /users/profile)
      final bloc = context.read<AuthBloc>();
      bloc.add(
        AuthProfileUpdateRequested(
          fullName: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          avatarUrl: avatarUrl,
        ),
      );

      // Đợi BLoC cập nhật state
      await bloc.stream
          .firstWhere((state) => state is AuthAuthenticated)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).t('edit_profile_updated')),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.of(context).t("edit_profile_error")}: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      // Chỉ lưu path local, chưa upload — upload khi nhấn Lưu
      setState(() {
        _localAvatarPath = image.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).t('edit_photo_selected')),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${S.of(context).t("edit_photo_error")}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('profile_edit_profile'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: PrimaryButton(
          label: S.of(context).t('edit_save'),
          loading: _isSaving,
          onPressed: _isSaving ? null : _saveProfile,
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                _buildHeroCard(context),
                const SizedBox(height: AppSpacing.xl),
                ModernCard(
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        label: S.of(context).t('edit_fullname'),
                        hint: S.of(context).t('edit_fullname_hint'),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          final result = Validators.combine([
                            Validators.required(value, fieldName: S.of(context).t('edit_name_field')),
                            Validators.minLength(value, 2, fieldName: S.of(context).t('edit_name_field')),
                            Validators.maxLength(
                              value,
                              AppConstants.maxNameLength,
                              fieldName: S.of(context).t('edit_name_field'),
                            ),
                          ]);
                          return result.isValid ? null : result.errorMessage;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomTextField(
                        controller: _bioController,
                        label: S.of(context).t('edit_bio'),
                        hint: S.of(context).t('edit_bio_hint'),
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          final result = Validators.maxLength(
                            value,
                            AppConstants.maxBioLength,
                            fieldName: S.of(context).t('edit_bio'),
                          );
                          return result.isValid ? null : result.errorMessage;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomTextField(
                        controller: _emailController,
                        label: S.of(context).t('edit_profile_email'),
                        readOnly: true,
                        enabled: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildGoalSection(context),
                const SizedBox(height: AppSpacing.xl),
                _buildDangerZone(context),
              ],
            ),
          ),
          if (_isBusy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.08),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return ModernCard(
          gradient: AppGradients.warmHero,
          elevated: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: S.of(context).t('edit_hero_title'),
                subtitle: S.of(context).t('edit_hero_desc'),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Stack(
                    children: [
                      Hero(
                        tag: 'profile-avatar',
                        child: CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white.withValues(alpha: 0.86),
                          backgroundImage: _getAvatarImage(user?.avatarUrl),
                          child:
                              (_localAvatarPath == null && user?.avatarUrl == null)
                                  ? Text(
                                    (user?.fullName.isNotEmpty ?? false)
                                        ? user!.fullName.substring(0, 1)
                                        : 'U',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(color: AppColors.primary),
                                  )
                                  : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: AppColors.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _pickAvatar,
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? S.of(context).t('notif_user_default'),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          S.of(context).t('edit_avatar_desc'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton.icon(
                          onPressed: _pickAvatar,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(S.of(context).t('edit_change_photo')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_localAvatarPath != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          S.of(context).t('edit_photo_confirm'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  ImageProvider? _getAvatarImage(String? networkUrl) {
    // Ưu tiên ảnh local nếu vừa chọn
    if (_localAvatarPath != null) {
      return FileImage(File(_localAvatarPath!));
    }
    if (networkUrl != null && networkUrl.isNotEmpty) {
      return NetworkImage(networkUrl);
    }
    return null;
  }

  Widget _buildGoalSection(BuildContext context) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: S.of(context).t('edit_goal_title'),
            subtitle: S.of(context).t('edit_goal_desc'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _GoalButton(
                icon: Icons.remove_rounded,
                onTap: _yearlyGoal > 1 ? () => setState(() => _yearlyGoal--) : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$_yearlyGoal',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      S.of(context).t('edit_books'),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
              _GoalButton(
                icon: Icons.add_rounded,
                onTap:
                    _yearlyGoal < 100 ? () => setState(() => _yearlyGoal++) : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Slider(
            value: _yearlyGoal.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: (value) => setState(() => _yearlyGoal = value.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return ModernCard(
      border: Border.all(color: AppColors.error.withValues(alpha: 0.24)),
      gradient: LinearGradient(
        colors: [
          AppColors.error.withValues(alpha: 0.06),
          Colors.white,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).t('edit_sensitive_title'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            S.of(context).t('edit_sensitive_desc'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          _DangerTile(
            icon: Icons.lock_outline_rounded,
            title: S.of(context).t('change_pw_btn'),
            subtitle: S.of(context).t('edit_pw_subtitle'),
            onTap: () => context.push('/settings/change-password'),
          ),
          const Divider(height: 1, indent: 56),
          _DangerTile(
            icon: Icons.delete_forever_outlined,
            title: S.of(context).t('edit_delete_account'),
            subtitle: S.of(context).t('edit_delete_warning'),
            onTap: _confirmDeleteAccount,
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(S.of(context).t('edit_delete_account')),
            content: Text(
              S.of(context).t('edit_delete_confirm'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(S.of(context).t('edit_cancel')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  setState(() => _isSaving = true);
                  try {
                    await _userService.deleteAccount();
                    if (!mounted) return;
                    context.read<AuthBloc>().add(const AuthLogoutRequested());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.of(context).t('edit_account_deleted'))),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${S.of(context).t("error")}: $e')),
                    );
                  }
                },
                child: Text(S.of(context).t('edit_delete_btn')),
              ),
            ],
          ),
    );
  }
}

class _GoalButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _GoalButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: onTap == null ? AppColors.textTertiary : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DangerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.error),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: AppColors.error),
      ),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.error,
      ),
    );
  }
}
