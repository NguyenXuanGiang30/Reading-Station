/// NotificationSettingsScreen - Cài đặt thông báo
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Notification settings
  bool _readingReminder = true;
  bool _reviewReminder = true;
  bool _goalProgress = true;
  bool _friendActivity = false;
  bool _achievements = true;
  bool _appUpdates = false;
  
  TimeOfDay _readingTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _reviewTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cài đặt thông báo',
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
          // Reading section
          _buildSection(
            title: 'Nhắc nhở đọc sách',
            children: [
              _buildSwitchTile(
                title: 'Nhắc nhở đọc hàng ngày',
                subtitle: 'Nhận thông báo để duy trì thói quen đọc',
                value: _readingReminder,
                onChanged: (v) => setState(() => _readingReminder = v),
                isDark: isDark,
              ),
              if (_readingReminder)
                _buildTimeTile(
                  title: 'Thời gian nhắc nhở',
                  time: _readingTime,
                  onTap: () => _selectTime(context, true),
                  isDark: isDark,
                ),
            ],
            isDark: isDark,
          ),
          
          const SizedBox(height: 20),
          
          // Review section
          _buildSection(
            title: 'Ôn tập Flashcard',
            children: [
              _buildSwitchTile(
                title: 'Nhắc nhở ôn tập',
                subtitle: 'Thông báo khi có thẻ cần ôn',
                value: _reviewReminder,
                onChanged: (v) => setState(() => _reviewReminder = v),
                isDark: isDark,
              ),
              if (_reviewReminder)
                _buildTimeTile(
                  title: 'Thời gian ôn tập',
                  time: _reviewTime,
                  onTap: () => _selectTime(context, false),
                  isDark: isDark,
                ),
            ],
            isDark: isDark,
          ),
          
          const SizedBox(height: 20),
          
          // Goals & Progress
          _buildSection(
            title: 'Mục tiêu & Tiến độ',
            children: [
              _buildSwitchTile(
                title: 'Cập nhật tiến độ',
                subtitle: 'Thông báo về tiến độ mục tiêu đọc sách',
                value: _goalProgress,
                onChanged: (v) => setState(() => _goalProgress = v),
                isDark: isDark,
              ),
              _buildSwitchTile(
                title: 'Thành tích',
                subtitle: 'Thông báo khi đạt thành tích mới',
                value: _achievements,
                onChanged: (v) => setState(() => _achievements = v),
                isDark: isDark,
              ),
            ],
            isDark: isDark,
          ),
          
          const SizedBox(height: 20),
          
          // Social
          _buildSection(
            title: 'Xã hội',
            children: [
              _buildSwitchTile(
                title: 'Hoạt động bạn bè',
                subtitle: 'Thông báo khi bạn bè có hoạt động mới',
                value: _friendActivity,
                onChanged: (v) => setState(() => _friendActivity = v),
                isDark: isDark,
              ),
            ],
            isDark: isDark,
          ),
          
          const SizedBox(height: 20),
          
          // App
          _buildSection(
            title: 'Ứng dụng',
            children: [
              _buildSwitchTile(
                title: 'Cập nhật ứng dụng',
                subtitle: 'Thông báo về tính năng mới và cập nhật',
                value: _appUpdates,
                onChanged: (v) => setState(() => _appUpdates = v),
                isDark: isDark,
              ),
            ],
            isDark: isDark,
          ),
          
          const SizedBox(height: 32),
          
          // Test notification button
          OutlinedButton.icon(
            onPressed: _testNotification,
            icon: const Icon(Icons.notifications_active),
            label: const Text('Gửi thông báo thử'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
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
            boxShadow: isDark ? [] : [
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

  Widget _buildTimeTile({
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryStart.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          time.format(context),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryStart,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isReading) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isReading ? _readingTime : _reviewTime,
    );
    
    if (time != null) {
      setState(() {
        if (isReading) {
          _readingTime = time;
        } else {
          _reviewTime = time;
        }
      });
    }
  }

  void _testNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Thông báo thử: Đã đến giờ đọc sách! 📚',
                style: GoogleFonts.inter(),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryStart,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
