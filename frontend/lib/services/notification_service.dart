/// NotificationService - Notification settings management
library;

import 'api_service.dart';

class NotificationService {
  final ApiService _api = ApiService();
  
  /// Get notification settings
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _api.get('/notifications/settings');
      return response.data ?? {};
    } catch (e) {
      throw Exception('Không thể tải cài đặt thông báo: $e');
    }
  }
  
  /// Update notification settings
  Future<Map<String, dynamic>> updateSettings({
    bool? reviewReminder,
    String? reminderTime,
    List<int>? daysOfWeek,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? friendActivity,
    bool? newFollower,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (reviewReminder != null) data['reviewReminder'] = reviewReminder;
      if (reminderTime != null) data['reminderTime'] = reminderTime;
      if (daysOfWeek != null) data['daysOfWeek'] = daysOfWeek;
      if (soundEnabled != null) data['soundEnabled'] = soundEnabled;
      if (vibrationEnabled != null) data['vibrationEnabled'] = vibrationEnabled;
      if (friendActivity != null) data['friendActivity'] = friendActivity;
      if (newFollower != null) data['newFollower'] = newFollower;
      
      final response = await _api.put('/notifications/settings', data: data);
      return response.data ?? {};
    } catch (e) {
      throw Exception('Không thể cập nhật cài đặt thông báo: $e');
    }
  }
}
