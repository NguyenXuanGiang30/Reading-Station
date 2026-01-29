/// SettingsScreen - Cài đặt ứng dụng
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/theme/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cài đặt',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Account section
          _buildSectionHeader('Tài khoản', isDark),
          _buildSettingCard([
            _buildSettingItem(
              icon: Icons.person_outline,
              title: 'Chỉnh sửa hồ sơ',
              onTap: () => context.push('/profile/edit'),
              isDark: isDark,
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.lock_outline,
              title: 'Đổi mật khẩu',
              onTap: () {},
              isDark: isDark,
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Quyền riêng tư',
              onTap: () {},
              isDark: isDark,
            ),
          ], isDark),
          
          const SizedBox(height: 24),
          
          // App settings section
          _buildSectionHeader('Ứng dụng', isDark),
          _buildSettingCard([
            _buildSwitchItem(
              icon: Icons.dark_mode_outlined,
              title: 'Chế độ tối',
              value: isDark,
              onChanged: (value) {
                context.read<ThemeCubit>().toggleTheme();
              },
              isDark: isDark,
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.notifications_outlined,
              title: 'Thông báo',
              subtitle: 'Nhắc nhở ôn tập, mục tiêu đọc',
              onTap: () => context.push('/settings/notifications'),
              isDark: isDark,
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.language_outlined,
              title: 'Ngôn ngữ',
              subtitle: 'Tiếng Việt',
              onTap: () {},
              isDark: isDark,
            ),
          ], isDark),
          
          const SizedBox(height: 24),
          
          // Reading goals section
          _buildSectionHeader('Mục tiêu đọc', isDark),
          _buildSettingCard([
            _buildSettingItem(
              icon: Icons.flag_outlined,
              title: 'Mục tiêu năm',
              subtitle: '24 cuốn sách',
              onTap: () {},
              isDark: isDark,
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.timer_outlined,
              title: 'Nhắc nhở đọc',
              subtitle: '20:00 mỗi ngày',
              onTap: () {},
              isDark: isDark,
            ),
          ], isDark),
          
          const SizedBox(height: 24),
          
          // Flashcard settings
          _buildSectionHeader('Flashcard', isDark),
          _buildSettingCard([
            _buildSettingItem(
              icon: Icons.style_outlined,
              title: 'Số thẻ mỗi phiên',
              subtitle: '20 thẻ',
              onTap: () {},
              isDark: isDark,
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.access_time,
              title: 'Nhắc nhở ôn tập',
              subtitle: '09:00 mỗi ngày',
              onTap: () {},
              isDark: isDark,
            ),
          ], isDark),
          
          const SizedBox(height: 24),
          
          // Data section
          _buildSectionHeader('Dữ liệu', isDark),
          _buildSettingCard([
            _buildSettingItem(
              icon: Icons.cloud_upload_outlined,
              title: 'Sao lưu dữ liệu',
              onTap: () {},
              isDark: isDark,
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.cloud_download_outlined,
              title: 'Khôi phục dữ liệu',
              onTap: () {},
              isDark: isDark,
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.download_outlined,
              title: 'Xuất dữ liệu',
              onTap: () {},
              isDark: isDark,
            ),
          ], isDark),
          
          const SizedBox(height: 24),
          
          // About section
          _buildSectionHeader('Thông tin', isDark),
          _buildSettingCard([
            _buildSettingItem(
              icon: Icons.info_outline,
              title: 'Về Trạm Đọc',
              onTap: () {},
              isDark: isDark,
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.description_outlined,
              title: 'Điều khoản sử dụng',
              onTap: () {},
              isDark: isDark,
            ),
            _buildDivider(),
            _buildSettingItem(
              icon: Icons.help_outline,
              title: 'Trợ giúp & Hỗ trợ',
              onTap: () {},
              isDark: isDark,
            ),
          ], isDark),
          
          const SizedBox(height: 32),
          
          // Logout button
          _buildLogoutButton(context, isDark),
          
          const SizedBox(height: 24),
          
          // App version
          Center(
            child: Text(
              'Phiên bản 1.0.0',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryStart.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryStart, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryStart.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryStart, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryStart,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 72);
  }

  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: Text(
          'Đăng xuất',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
