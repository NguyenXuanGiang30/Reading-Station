/// PrivacySettingsScreen - Cai dat quyen rieng tu
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/settings/settings_section_card.dart';
import '../../widgets/settings/settings_tile.dart';
import '../../l10n/app_localizations.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  bool _publicProfile = true;
  bool _showLibrary = true;
  bool _shareProgress = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final publicProfile = await _settingsService.isPublicProfile();
    final showLibrary = await _settingsService.isShowLibrary();
    final shareProgress = await _settingsService.isShareProgress();

    if (!mounted) return;
    setState(() {
      _publicProfile = publicProfile;
      _showLibrary = showLibrary;
      _shareProgress = shareProgress;
      _isLoading = false;
    });
  }

  Future<void> _updatePublicProfile(bool value) async {
    setState(() => _publicProfile = value);
    await _settingsService.setPublicProfile(value);
  }

  Future<void> _updateShowLibrary(bool value) async {
    setState(() => _showLibrary = value);
    await _settingsService.setShowLibrary(value);
  }

  Future<void> _updateShareProgress(bool value) async {
    setState(() => _shareProgress = value);
    await _settingsService.setShareProgress(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: S.of(context).t('privacy_title'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: AppSpacing.xl),
                  SettingsSectionCard(
                    title: S.of(context).t('privacy_profile_section'),
                    subtitle:
                        S.of(context).t('privacy_profile_desc'),
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.public_rounded,
                        title: S.of(context).t('privacy_public_profile'),
                        subtitle: S.of(context).t('privacy_public_desc'),
                        value: _publicProfile,
                        onChanged: _updatePublicProfile,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SettingsSectionCard(
                    title: S.of(context).t('privacy_library_section'),
                    subtitle:
                        S.of(context).t('privacy_library_desc'),
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.menu_book_rounded,
                        title: S.of(context).t('privacy_show_reading'),
                        subtitle:
                            S.of(context).t('privacy_show_reading_desc'),
                        value: _showLibrary,
                        onChanged: _updateShowLibrary,
                      ),
                      SettingsSwitchTile(
                        icon: Icons.trending_up_rounded,
                        title: S.of(context).t('privacy_show_stats'),
                        subtitle:
                            S.of(context).t('privacy_show_stats_desc'),
                        value: _shareProgress,
                        onChanged: _updateShareProgress,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ModernCard(
                    padding: const EdgeInsets.all(20),
                    child: SectionHeader(
                      title: S.of(context).t('privacy_note'),
                      subtitle:
                          S.of(context).t('privacy_note_desc'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroCard() {
    return ModernCard(
      gradient: AppGradients.warmHero,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.privacy_tip_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).t('privacy_hero_title'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  S.of(context).t('privacy_hero_desc'),
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
