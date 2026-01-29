/// FlashcardSettingsScreen - Cài đặt Flashcard
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../services/settings_service.dart';

class FlashcardSettingsScreen extends StatefulWidget {
  const FlashcardSettingsScreen({super.key});

  @override
  State<FlashcardSettingsScreen> createState() => _FlashcardSettingsScreenState();
}

class _FlashcardSettingsScreenState extends State<FlashcardSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  
  int _cardsPerSession = 20;
  bool _reviewReminderEnabled = true;
  TimeOfDay _reviewTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;

  final List<int> _cardOptions = [5, 10, 15, 20, 25, 30, 40, 50];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cards = await _settingsService.getCardsPerSession();
    final reminderEnabled = await _settingsService.isReviewReminderEnabled();
    final timeMap = await _settingsService.getReviewReminderTime();
    
    if (mounted) {
      setState(() {
        _cardsPerSession = cards;
        _reviewReminderEnabled = reminderEnabled;
        _reviewTime = TimeOfDay(hour: timeMap['hour']!, minute: timeMap['minute']!);
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reviewTime,
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
      setState(() => _reviewTime = time);
      await _settingsService.setReviewReminderTime(time.hour, time.minute);
    }
  }

  Future<void> _save() async {
    await _settingsService.setCardsPerSession(_cardsPerSession);
    await _settingsService.setReviewReminderEnabled(_reviewReminderEnabled);
    await _settingsService.setReviewReminderTime(_reviewTime.hour, _reviewTime.minute);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã lưu cài đặt Flashcard',
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
          'Cài đặt Flashcard',
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
                      // Cards per session section
                      _buildSection(
                        title: 'Số thẻ mỗi phiên',
                        child: Container(
                          padding: const EdgeInsets.all(20),
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
                          child: Column(
                            children: [
                              // Display current value
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.primaryStart, AppColors.primaryEnd],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.style, color: Colors.white, size: 28),
                                    const SizedBox(width: 12),
                                    Text(
                                      '$_cardsPerSession thẻ',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Options grid
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: _cardOptions.map((value) {
                                  final isSelected = _cardsPerSession == value;
                                  return GestureDetector(
                                    onTap: () => setState(() => _cardsPerSession = value),
                                    child: Container(
                                      width: 70,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? AppColors.primaryStart 
                                            : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected 
                                              ? AppColors.primaryStart 
                                              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                        ),
                                      ),
                                      child: Text(
                                        '$value',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected 
                                              ? Colors.white 
                                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        isDark: isDark,
                      ),

                      const SizedBox(height: 24),

                      // Review reminder section
                      _buildSection(
                        title: 'Nhắc nhở ôn tập',
                        child: Container(
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
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: Text(
                                  'Bật nhắc nhở',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                subtitle: Text(
                                  'Thông báo khi có thẻ cần ôn tập',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                value: _reviewReminderEnabled,
                                onChanged: (value) => setState(() => _reviewReminderEnabled = value),
                                activeTrackColor: AppColors.primaryStart,
                              ),
                              if (_reviewReminderEnabled) ...[
                                const Divider(height: 1),
                                ListTile(
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
                                      _reviewTime.format(context),
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryStart,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        isDark: isDark,
                      ),

                      const SizedBox(height: 24),

                      // Tips
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline, color: AppColors.info, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ôn tập đều đặn với Spaced Repetition giúp ghi nhớ lâu hơn 90% so với học thông thường.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildSection({
    required String title,
    required Widget child,
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
        child,
      ],
    );
  }
}
