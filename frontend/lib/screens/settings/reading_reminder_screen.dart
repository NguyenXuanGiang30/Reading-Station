/// ReadingReminderScreen - Cài đặt nhắc nhở đọc sách
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../services/settings_service.dart';

class ReadingReminderScreen extends StatefulWidget {
  const ReadingReminderScreen({super.key});

  @override
  State<ReadingReminderScreen> createState() => _ReadingReminderScreenState();
}

class _ReadingReminderScreenState extends State<ReadingReminderScreen> {
  final SettingsService _settingsService = SettingsService();
  
  bool _enabled = true;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _settingsService.isReadingReminderEnabled();
    final timeMap = await _settingsService.getReadingReminderTime();
    
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _time = TimeOfDay(hour: timeMap['hour']!, minute: timeMap['minute']!);
        _isLoading = false;
      });
    }
  }

  Future<void> _updateEnabled(bool value) async {
    setState(() => _enabled = value);
    await _settingsService.setReadingReminderEnabled(value);
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryStart,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (time != null && mounted) {
      setState(() => _time = time);
      await _settingsService.setReadingReminderTime(time.hour, time.minute);
    }
  }

  Future<void> _save() async {
    await _settingsService.setReadingReminderEnabled(_enabled);
    await _settingsService.setReadingReminderTime(_time.hour, _time.minute);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _enabled 
                ? 'Đã bật nhắc nhở lúc ${_time.format(context)}' 
                : 'Đã tắt nhắc nhở đọc sách',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nhắc nhở đọc sách',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Preview
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _enabled 
                                ? [AppColors.primaryStart, AppColors.primaryEnd]
                                : [Colors.grey.shade400, Colors.grey.shade500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _enabled ? Icons.notifications_active : Icons.notifications_off,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _enabled ? _time.format(context) : 'Đã tắt',
                              style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (_enabled)
                              Text(
                                'mỗi ngày',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Enable toggle
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
                        child: SwitchListTile(
                          title: Text(
                            'Bật nhắc nhở',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          subtitle: Text(
                            'Nhận thông báo nhắc đọc sách mỗi ngày',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          value: _enabled,
                          onChanged: _updateEnabled,
                          activeTrackColor: AppColors.primaryStart,
                        ),
                      ),

                      if (_enabled) ...[
                        const SizedBox(height: 16),

                        // Time picker
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
                          child: ListTile(
                            onTap: _selectTime,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryStart.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.access_time, color: AppColors.primaryStart, size: 20),
                            ),
                            title: Text(
                              'Thời gian',
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
                                _time.format(context),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryStart,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Quick time options
                        Text(
                          'Gợi ý thời gian',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            {'label': 'Sáng sớm', 'hour': 6, 'minute': 30},
                            {'label': 'Trưa', 'hour': 12, 'minute': 0},
                            {'label': 'Chiều', 'hour': 17, 'minute': 0},
                            {'label': 'Tối', 'hour': 20, 'minute': 0},
                            {'label': 'Đêm khuya', 'hour': 22, 'minute': 0},
                          ].map((option) {
                            final isSelected = _time.hour == option['hour'] && _time.minute == option['minute'];
                            return GestureDetector(
                              onTap: () async {
                                final newTime = TimeOfDay(hour: option['hour'] as int, minute: option['minute'] as int);
                                setState(() => _time = newTime);
                                await _settingsService.setReadingReminderTime(newTime.hour, newTime.minute);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryStart : (isDark ? AppColors.cardDark : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primaryStart : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                  ),
                                ),
                                child: Text(
                                  option['label'] as String,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Save button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryStart,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Lưu cài đặt',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
