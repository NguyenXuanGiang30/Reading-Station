/// SettingsService - Manages app settings with API sync and local cache
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class SettingsService {
  final ApiService _api = ApiService();
  
  static const String _keyReadingGoal = 'reading_goal';
  static const String _keyReadingReminderEnabled = 'reading_reminder_enabled';
  static const String _keyReadingReminderHour = 'reading_reminder_hour';
  static const String _keyReadingReminderMinute = 'reading_reminder_minute';
  static const String _keyReviewReminderEnabled = 'review_reminder_enabled';
  static const String _keyReviewReminderHour = 'review_reminder_hour';
  static const String _keyReviewReminderMinute = 'review_reminder_minute';
  static const String _keyCardsPerSession = 'cards_per_session';
  static const String _keyLanguage = 'language';
  static const String _keyProfileVisibility = 'profile_visibility';
  static const String _keyActivitySharing = 'activity_sharing';
  static const String _keyAllowFriendRequests = 'allow_friend_requests';
  static const String _keySynced = 'settings_synced';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============ Sync with Server ============
  
  /// Fetch settings from server and cache locally
  Future<void> syncFromServer() async {
    try {
      final response = await _api.get('/settings');
      if (response.data != null) {
        final data = response.data as Map<String, dynamic>;
        await _cacheSettings(data);
      }
    } catch (e) {
      // Fallback to local cache if offline
    }
  }
  
  /// Update settings on server
  Future<void> _updateServer(Map<String, dynamic> updates) async {
    try {
      await _api.put('/settings', data: updates);
    } catch (e) {
      // Silently fail - settings are cached locally
    }
  }
  
  /// Cache settings from server response
  Future<void> _cacheSettings(Map<String, dynamic> data) async {
    final prefs = await _preferences;
    
    if (data['language'] != null) {
      await prefs.setString(_keyLanguage, data['language']);
    }
    if (data['readingGoal'] != null) {
      await prefs.setInt(_keyReadingGoal, data['readingGoal']);
    }
    if (data['readingReminderEnabled'] != null) {
      await prefs.setBool(_keyReadingReminderEnabled, data['readingReminderEnabled']);
    }
    if (data['readingReminderTime'] != null) {
      final parts = (data['readingReminderTime'] as String).split(':');
      if (parts.length >= 2) {
        await prefs.setInt(_keyReadingReminderHour, int.parse(parts[0]));
        await prefs.setInt(_keyReadingReminderMinute, int.parse(parts[1]));
      }
    }
    if (data['cardsPerSession'] != null) {
      await prefs.setInt(_keyCardsPerSession, data['cardsPerSession']);
    }
    if (data['reviewReminderEnabled'] != null) {
      await prefs.setBool(_keyReviewReminderEnabled, data['reviewReminderEnabled']);
    }
    if (data['reviewReminderTime'] != null) {
      final parts = (data['reviewReminderTime'] as String).split(':');
      if (parts.length >= 2) {
        await prefs.setInt(_keyReviewReminderHour, int.parse(parts[0]));
        await prefs.setInt(_keyReviewReminderMinute, int.parse(parts[1]));
      }
    }
    if (data['profileVisibility'] != null) {
      await prefs.setString(_keyProfileVisibility, data['profileVisibility']);
    }
    if (data['activitySharing'] != null) {
      await prefs.setBool(_keyActivitySharing, data['activitySharing']);
    }
    if (data['allowFriendRequests'] != null) {
      await prefs.setBool(_keyAllowFriendRequests, data['allowFriendRequests']);
    }
    
    await prefs.setBool(_keySynced, true);
  }

  // ============ Change Password ============
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _api.post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
    
    if (response.statusCode != 200) {
      throw Exception(response.data?['message'] ?? 'Không thể đổi mật khẩu');
    }
  }

  // ============ Reading Goal ============
  Future<int> getReadingGoal() async {
    final prefs = await _preferences;
    return prefs.getInt(_keyReadingGoal) ?? 24;
  }

  Future<void> setReadingGoal(int goal) async {
    final prefs = await _preferences;
    await prefs.setInt(_keyReadingGoal, goal);
    await _updateServer({'readingGoal': goal});
  }

  // ============ Reading Reminder ============
  Future<bool> isReadingReminderEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyReadingReminderEnabled) ?? true;
  }

  Future<void> setReadingReminderEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_keyReadingReminderEnabled, enabled);
    await _updateServer({'readingReminderEnabled': enabled});
  }

  Future<Map<String, int>> getReadingReminderTime() async {
    final prefs = await _preferences;
    return {
      'hour': prefs.getInt(_keyReadingReminderHour) ?? 20,
      'minute': prefs.getInt(_keyReadingReminderMinute) ?? 0,
    };
  }

  Future<void> setReadingReminderTime(int hour, int minute) async {
    final prefs = await _preferences;
    await prefs.setInt(_keyReadingReminderHour, hour);
    await prefs.setInt(_keyReadingReminderMinute, minute);
    final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    await _updateServer({'readingReminderTime': timeStr});
  }

  // ============ Review Reminder ============
  Future<bool> isReviewReminderEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyReviewReminderEnabled) ?? true;
  }

  Future<void> setReviewReminderEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_keyReviewReminderEnabled, enabled);
    await _updateServer({'reviewReminderEnabled': enabled});
  }

  Future<Map<String, int>> getReviewReminderTime() async {
    final prefs = await _preferences;
    return {
      'hour': prefs.getInt(_keyReviewReminderHour) ?? 9,
      'minute': prefs.getInt(_keyReviewReminderMinute) ?? 0,
    };
  }

  Future<void> setReviewReminderTime(int hour, int minute) async {
    final prefs = await _preferences;
    await prefs.setInt(_keyReviewReminderHour, hour);
    await prefs.setInt(_keyReviewReminderMinute, minute);
    final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    await _updateServer({'reviewReminderTime': timeStr});
  }

  // ============ Flashcard Settings ============
  Future<int> getCardsPerSession() async {
    final prefs = await _preferences;
    return prefs.getInt(_keyCardsPerSession) ?? 20;
  }

  Future<void> setCardsPerSession(int cards) async {
    final prefs = await _preferences;
    await prefs.setInt(_keyCardsPerSession, cards);
    await _updateServer({'cardsPerSession': cards});
  }

  // ============ Language ============
  Future<String> getLanguage() async {
    final prefs = await _preferences;
    return prefs.getString(_keyLanguage) ?? 'vi';
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = await _preferences;
    await prefs.setString(_keyLanguage, languageCode);
    await _updateServer({'language': languageCode});
  }

  // ============ Privacy Settings ============
  Future<String> getProfileVisibility() async {
    final prefs = await _preferences;
    return prefs.getString(_keyProfileVisibility) ?? 'public';
  }

  Future<void> setProfileVisibility(String visibility) async {
    final prefs = await _preferences;
    await prefs.setString(_keyProfileVisibility, visibility);
    await _updateServer({'profileVisibility': visibility});
  }
  
  Future<bool> isActivitySharing() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyActivitySharing) ?? true;
  }

  Future<void> setActivitySharing(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_keyActivitySharing, enabled);
    await _updateServer({'activitySharing': enabled});
  }
  
  Future<bool> isAllowFriendRequests() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyAllowFriendRequests) ?? true;
  }

  Future<void> setAllowFriendRequests(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_keyAllowFriendRequests, enabled);
    await _updateServer({'allowFriendRequests': enabled});
  }
  
  // Legacy methods for backward compatibility
  Future<bool> isPublicProfile() async {
    final visibility = await getProfileVisibility();
    return visibility == 'public';
  }

  Future<void> setPublicProfile(bool isPublic) async {
    await setProfileVisibility(isPublic ? 'public' : 'private');
  }

  Future<bool> isShowLibrary() async {
    return await isActivitySharing();
  }

  Future<void> setShowLibrary(bool show) async {
    await setActivitySharing(show);
  }

  Future<bool> isShareProgress() async {
    return await isActivitySharing();
  }

  Future<void> setShareProgress(bool share) async {
    await setActivitySharing(share);
  }

  // ============ Export All Settings ============
  Future<Map<String, dynamic>> exportSettings() async {
    return {
      'readingGoal': await getReadingGoal(),
      'readingReminderEnabled': await isReadingReminderEnabled(),
      'readingReminderTime': await getReadingReminderTime(),
      'reviewReminderEnabled': await isReviewReminderEnabled(),
      'reviewReminderTime': await getReviewReminderTime(),
      'cardsPerSession': await getCardsPerSession(),
      'language': await getLanguage(),
      'profileVisibility': await getProfileVisibility(),
      'activitySharing': await isActivitySharing(),
      'allowFriendRequests': await isAllowFriendRequests(),
    };
  }

  // ============ Import Settings ============
  Future<void> importSettings(Map<String, dynamic> settings) async {
    if (settings['readingGoal'] != null) {
      await setReadingGoal(settings['readingGoal']);
    }
    if (settings['readingReminderEnabled'] != null) {
      await setReadingReminderEnabled(settings['readingReminderEnabled']);
    }
    if (settings['readingReminderTime'] != null) {
      final time = settings['readingReminderTime'] as Map<String, dynamic>;
      await setReadingReminderTime(time['hour'] ?? 20, time['minute'] ?? 0);
    }
    if (settings['reviewReminderEnabled'] != null) {
      await setReviewReminderEnabled(settings['reviewReminderEnabled']);
    }
    if (settings['reviewReminderTime'] != null) {
      final time = settings['reviewReminderTime'] as Map<String, dynamic>;
      await setReviewReminderTime(time['hour'] ?? 9, time['minute'] ?? 0);
    }
    if (settings['cardsPerSession'] != null) {
      await setCardsPerSession(settings['cardsPerSession']);
    }
    if (settings['language'] != null) {
      await setLanguage(settings['language']);
    }
    if (settings['profileVisibility'] != null) {
      await setProfileVisibility(settings['profileVisibility']);
    }
    if (settings['activitySharing'] != null) {
      await setActivitySharing(settings['activitySharing']);
    }
    if (settings['allowFriendRequests'] != null) {
      await setAllowFriendRequests(settings['allowFriendRequests']);
    }
  }
}
