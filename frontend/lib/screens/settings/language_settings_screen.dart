/// LanguageSettingsScreen - Cài đặt ngôn ngữ
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../services/settings_service.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  
  String _selectedLanguage = 'vi';
  bool _isLoading = true;

  final List<Map<String, String>> _languages = [
    {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final language = await _settingsService.getLanguage();
    if (mounted) {
      setState(() {
        _selectedLanguage = language;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectLanguage(String code) async {
    setState(() => _selectedLanguage = code);
    await _settingsService.setLanguage(code);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            code == 'vi' 
                ? 'Đã chuyển sang Tiếng Việt' 
                : 'Switched to English',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ngôn ngữ',
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
                      Icon(Icons.translate, color: AppColors.primaryStart),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chọn ngôn ngữ hiển thị cho ứng dụng.',
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

                // Language list
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
                  child: Column(
                    children: _languages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final lang = entry.value;
                      final isSelected = _selectedLanguage == lang['code'];
                      
                      return Column(
                        children: [
                          ListTile(
                            onTap: () => _selectLanguage(lang['code']!),
                            leading: Text(
                              lang['flag']!,
                              style: const TextStyle(fontSize: 28),
                            ),
                            title: Text(
                              lang['name']!,
                              style: GoogleFonts.inter(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected 
                                    ? AppColors.primaryStart 
                                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              ),
                            ),
                            trailing: isSelected
                                ? Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryStart,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  )
                                : null,
                          ),
                          if (index < _languages.length - 1)
                            const Divider(height: 1, indent: 72),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 32),

                // Note
                Text(
                  'Lưu ý: Một số nội dung có thể vẫn hiển thị bằng ngôn ngữ gốc.',
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
}
