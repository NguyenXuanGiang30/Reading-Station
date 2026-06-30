import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool isLoading;
  final String? error;
  
  // Settings values
  final int readingGoal;
  final bool readingReminderEnabled;
  final int readingReminderHour;
  final int readingReminderMinute;
  
  final bool reviewReminderEnabled;
  final int reviewReminderHour;
  final int reviewReminderMinute;
  
  final int cardsPerSession;
  final String language;
  
  final String profileVisibility;
  final bool activitySharing;
  final bool allowFriendRequests;

  const SettingsState({
    this.isLoading = true,
    this.error,
    this.readingGoal = 24,
    this.readingReminderEnabled = true,
    this.readingReminderHour = 20,
    this.readingReminderMinute = 0,
    this.reviewReminderEnabled = true,
    this.reviewReminderHour = 9,
    this.reviewReminderMinute = 0,
    this.cardsPerSession = 20,
    this.language = 'vi',
    this.profileVisibility = 'public',
    this.activitySharing = true,
    this.allowFriendRequests = true,
  });

  SettingsState copyWith({
    bool? isLoading,
    String? error,
    int? readingGoal,
    bool? readingReminderEnabled,
    int? readingReminderHour,
    int? readingReminderMinute,
    bool? reviewReminderEnabled,
    int? reviewReminderHour,
    int? reviewReminderMinute,
    int? cardsPerSession,
    String? language,
    String? profileVisibility,
    bool? activitySharing,
    bool? allowFriendRequests,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Clear error by default or pass it explicitly
      readingGoal: readingGoal ?? this.readingGoal,
      readingReminderEnabled: readingReminderEnabled ?? this.readingReminderEnabled,
      readingReminderHour: readingReminderHour ?? this.readingReminderHour,
      readingReminderMinute: readingReminderMinute ?? this.readingReminderMinute,
      reviewReminderEnabled: reviewReminderEnabled ?? this.reviewReminderEnabled,
      reviewReminderHour: reviewReminderHour ?? this.reviewReminderHour,
      reviewReminderMinute: reviewReminderMinute ?? this.reviewReminderMinute,
      cardsPerSession: cardsPerSession ?? this.cardsPerSession,
      language: language ?? this.language,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      activitySharing: activitySharing ?? this.activitySharing,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        error,
        readingGoal,
        readingReminderEnabled,
        readingReminderHour,
        readingReminderMinute,
        reviewReminderEnabled,
        reviewReminderHour,
        reviewReminderMinute,
        cardsPerSession,
        language,
        profileVisibility,
        activitySharing,
        allowFriendRequests,
      ];
}
