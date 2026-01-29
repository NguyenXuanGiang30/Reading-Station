/// PrivacySettingsScreen - Cài đặt quyền riêng tư
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../services/settings_service.dart';

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
    
    if (mounted) {
      setState(() {
        _publicProfile = publicProfile;
        _showLibrary = showLibrary;
        _shareProgress = shareProgress;
        _isLoading = false;
      });
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quyền riêng tư',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryStart.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.privacy_tip_outlined, color: AppColors.primaryStart),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Kiểm soát những gì người khác có thể thấy về bạn.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Profile visibility
                _buildSection(
                  title: 'Hiển thị hồ sơ',
                  children: [
                    _buildSwitchTile(
                      title: 'Hồ sơ công khai',
                      subtitle: 'Cho phép mọi người xem hồ sơ của bạn',
                      value: _publicProfile,
                      onChanged: _updatePublicProfile,
                      isDark: isDark,
                    ),
                  ],
                  isDark: isDark,
                ),

                const SizedBox(height: 20),

                // Library & Reading
                _buildSection(
                  title: 'Thư viện & Đọc sách',
                  children: [
                    _buildSwitchTile(
                      title: 'Hiển thị thư viện sách',
                      subtitle: 'Cho phép bạn bè xem các sách bạn đang đọc',
                      value: _showLibrary,
                      onChanged: _updateShowLibrary,
                      isDark: isDark,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildSwitchTile(
                      title: 'Chia sẻ tiến độ đọc',
                      subtitle: 'Hiển thị tiến độ đọc sách trong hoạt động',
                      value: _shareProgress,
                      onChanged: _updateShareProgress,
                      isDark: isDark,
                    ),
                  ],
                  isDark: isDark,
                ),

                const SizedBox(height: 32),

                // Note
                Text(
                  'Lưu ý: Các cài đặt này chỉ ảnh hưởng đến việc hiển thị trên ứng dụng. Dữ liệu của bạn luôn được bảo mật.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required bool isDark,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primaryStart,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
