import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/settings_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsService _settingsService;

  SettingsBloc({SettingsService? settingsService})
      : _settingsService = settingsService ?? SettingsService(),
        super(const SettingsState()) {
    on<SettingsLoadRequested>(_onLoadRequested);
    on<SettingsUpdateGoalRequested>(_onUpdateGoal);
    on<SettingsUpdateReadingReminderRequested>(_onUpdateReadingReminder);
    on<SettingsUpdateReviewReminderRequested>(_onUpdateReviewReminder);
    on<SettingsUpdateFlashcardSettingsRequested>(_onUpdateFlashcardSettings);
    on<SettingsUpdateLanguageRequested>(_onUpdateLanguage);
    on<SettingsUpdatePrivacyRequested>(_onUpdatePrivacy);
    on<SettingsSyncRequested>(_onSyncRequested);
  }

  Future<void> _onLoadRequested(
      SettingsLoadRequested event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final goal = await _settingsService.getReadingGoal();
      final readRemEn = await _settingsService.isReadingReminderEnabled();
      final readRemTime = await _settingsService.getReadingReminderTime();
      final revRemEn = await _settingsService.isReviewReminderEnabled();
      final revRemTime = await _settingsService.getReviewReminderTime();
      final cards = await _settingsService.getCardsPerSession();
      final lang = await _settingsService.getLanguage();
      final profVis = await _settingsService.getProfileVisibility();
      final actShare = await _settingsService.isActivitySharing();
      final askFriends = await _settingsService.isAllowFriendRequests();

      emit(state.copyWith(
        isLoading: false,
        readingGoal: goal,
        readingReminderEnabled: readRemEn,
        readingReminderHour: readRemTime['hour'],
        readingReminderMinute: readRemTime['minute'],
        reviewReminderEnabled: revRemEn,
        reviewReminderHour: revRemTime['hour'],
        reviewReminderMinute: revRemTime['minute'],
        cardsPerSession: cards,
        language: lang,
        profileVisibility: profVis,
        activitySharing: actShare,
        allowFriendRequests: askFriends,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Không thể tải cài đặt: $e'));
    }
  }

  Future<void> _onUpdateGoal(
      SettingsUpdateGoalRequested event, Emitter<SettingsState> emit) async {
    try {
      // Optimistic update
      emit(state.copyWith(readingGoal: event.goal, error: null));
      await _settingsService.setReadingGoal(event.goal);
    } catch (e) {
      emit(state.copyWith(error: 'Không thể cập nhật mục tiêu: $e'));
      // Could revert if we stored previous state, but we'll fetch again or ignore
    }
  }

  Future<void> _onUpdateReadingReminder(
      SettingsUpdateReadingReminderRequested event, Emitter<SettingsState> emit) async {
    try {
      emit(state.copyWith(
        readingReminderEnabled: event.enabled,
        readingReminderHour: event.hour,
        readingReminderMinute: event.minute,
        error: null,
      ));
      await _settingsService.setReadingReminderEnabled(event.enabled);
      await _settingsService.setReadingReminderTime(event.hour, event.minute);
    } catch (e) {
      emit(state.copyWith(error: 'Lỗi cập nhật thông báo đọc sách: $e'));
    }
  }

  Future<void> _onUpdateReviewReminder(
      SettingsUpdateReviewReminderRequested event, Emitter<SettingsState> emit) async {
    try {
      emit(state.copyWith(
        reviewReminderEnabled: event.enabled,
        reviewReminderHour: event.hour,
        reviewReminderMinute: event.minute,
        error: null,
      ));
      await _settingsService.setReviewReminderEnabled(event.enabled);
      await _settingsService.setReviewReminderTime(event.hour, event.minute);
    } catch (e) {
      emit(state.copyWith(error: 'Lỗi cập nhật thông báo ôn tập: $e'));
    }
  }

  Future<void> _onUpdateFlashcardSettings(
      SettingsUpdateFlashcardSettingsRequested event, Emitter<SettingsState> emit) async {
    try {
      emit(state.copyWith(cardsPerSession: event.cardsPerSession, error: null));
      await _settingsService.setCardsPerSession(event.cardsPerSession);
    } catch (e) {
      emit(state.copyWith(error: 'Lỗi cập nhật flashcard: $e'));
    }
  }

  Future<void> _onUpdateLanguage(
      SettingsUpdateLanguageRequested event, Emitter<SettingsState> emit) async {
    try {
      emit(state.copyWith(language: event.language, error: null));
      await _settingsService.setLanguage(event.language);
    } catch (e) {
      emit(state.copyWith(error: 'Lỗi cập nhật ngôn ngữ: $e'));
    }
  }

  Future<void> _onUpdatePrivacy(
      SettingsUpdatePrivacyRequested event, Emitter<SettingsState> emit) async {
    try {
      emit(state.copyWith(
        profileVisibility: event.profileVisibility,
        activitySharing: event.activitySharing,
        allowFriendRequests: event.allowFriendRequests,
        error: null,
      ));
      await _settingsService.setProfileVisibility(event.profileVisibility);
      await _settingsService.setActivitySharing(event.activitySharing);
      await _settingsService.setAllowFriendRequests(event.allowFriendRequests);
    } catch (e) {
      emit(state.copyWith(error: 'Lỗi cập nhật quyền riêng tư: $e'));
    }
  }

  Future<void> _onSyncRequested(
      SettingsSyncRequested event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _settingsService.syncFromServer();
      // Reload values to state
      add(SettingsLoadRequested());
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Lỗi đồng bộ: $e'));
      // Proceed to load local anyway
      add(SettingsLoadRequested());
    }
  }
}
