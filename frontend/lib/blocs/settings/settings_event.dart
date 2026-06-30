import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class SettingsLoadRequested extends SettingsEvent {}

class SettingsUpdateGoalRequested extends SettingsEvent {
  final int goal;
  const SettingsUpdateGoalRequested(this.goal);
  @override
  List<Object?> get props => [goal];
}

class SettingsUpdateReadingReminderRequested extends SettingsEvent {
  final bool enabled;
  final int hour;
  final int minute;
  const SettingsUpdateReadingReminderRequested({required this.enabled, required this.hour, required this.minute});
  @override
  List<Object?> get props => [enabled, hour, minute];
}

class SettingsUpdateReviewReminderRequested extends SettingsEvent {
  final bool enabled;
  final int hour;
  final int minute;
  const SettingsUpdateReviewReminderRequested({required this.enabled, required this.hour, required this.minute});
  @override
  List<Object?> get props => [enabled, hour, minute];
}

class SettingsUpdateFlashcardSettingsRequested extends SettingsEvent {
  final int cardsPerSession;
  const SettingsUpdateFlashcardSettingsRequested(this.cardsPerSession);
  @override
  List<Object?> get props => [cardsPerSession];
}

class SettingsUpdateLanguageRequested extends SettingsEvent {
  final String language;
  const SettingsUpdateLanguageRequested(this.language);
  @override
  List<Object?> get props => [language];
}

class SettingsUpdatePrivacyRequested extends SettingsEvent {
  final String profileVisibility;
  final bool activitySharing;
  final bool allowFriendRequests;
  const SettingsUpdatePrivacyRequested({
    required this.profileVisibility,
    required this.activitySharing,
    required this.allowFriendRequests,
  });
  @override
  List<Object?> get props => [profileVisibility, activitySharing, allowFriendRequests];
}

class SettingsSyncRequested extends SettingsEvent {}
