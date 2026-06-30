/// Environment Configuration
/// Supports multiple environments: development, staging, production
library;

import 'package:flutter/foundation.dart';

enum AppEnvironment { development, staging, production }

class EnvironmentConfig {
  final AppEnvironment environment;
  final String name;
  final String apiBaseUrl;
  final String apiVersion;
  final bool enableLogging;
  final bool showDebugBanner;
  final int connectTimeout;
  final int receiveTimeout;

  const EnvironmentConfig({
    required this.environment,
    required this.name,
    required this.apiBaseUrl,
    required this.apiVersion,
    required this.enableLogging,
    required this.showDebugBanner,
    required this.connectTimeout,
    required this.receiveTimeout,
  });

  String get fullApiUrl => '$apiBaseUrl$apiVersion';

  bool get isProduction => environment == AppEnvironment.production;
  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isStaging => environment == AppEnvironment.staging;

  static EnvironmentConfig get current {
    if (kReleaseMode) {
      return production;
    }

    final envOverride = const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    ).toLowerCase();
    switch (envOverride) {
      case 'production':
        return production;
      case 'staging':
        return staging;
      default:
        return development;
    }
  }

  static EnvironmentConfig get development {
    final override = const String.fromEnvironment('DEV_API_BASE_URL');
    final apiBaseUrl = override.isNotEmpty
        ? override
        : _defaultDevelopmentApiBaseUrl();

    return EnvironmentConfig(
      environment: AppEnvironment.development,
      name: 'development',
      apiBaseUrl: apiBaseUrl,
      apiVersion: '/api/v1',
      enableLogging: true,
      showDebugBanner: true,
      connectTimeout: 30000,
      receiveTimeout: 30000,
    );
  }

  static EnvironmentConfig get staging {
    final override = const String.fromEnvironment('STAGING_API_BASE_URL');
    return EnvironmentConfig(
      environment: AppEnvironment.staging,
      name: 'staging',
      apiBaseUrl: override.isNotEmpty
          ? override
          : 'https://staging-api.tuyendungvn.id.vn',
      apiVersion: '/api/v1',
      enableLogging: true,
      showDebugBanner: true,
      connectTimeout: 30000,
      receiveTimeout: 30000,
    );
  }

  static EnvironmentConfig get production {
    final apiBaseUrl = const String.fromEnvironment(
      'PROD_API_BASE_URL',
      defaultValue: 'https://tramdoc-api.dichvu.cloud',
    );

    return EnvironmentConfig(
      environment: AppEnvironment.production,
      name: 'production',
      apiBaseUrl: apiBaseUrl,
      apiVersion: '/api/v1',
      enableLogging: false,
      showDebugBanner: false,
      connectTimeout: 30000,
      receiveTimeout: 30000,
    );
  }

  static String _defaultDevelopmentApiBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Dùng IP WiFi máy tính để điện thoại thật kết nối được.
        // Nếu dùng emulator, đổi thành 'http://10.0.2.2:8080'
        return 'https://tramdoc-api.dichvu.cloud';
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return 'http://localhost:8080';
    }
  }
}

/// API Endpoints - All API paths defined here for consistency
class ApiEndpoints {
  // Auth endpoints
  static const String auth = '/auth';
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh';
  static const String googleLogin = '$auth/google';
  static const String facebookLogin = '$auth/facebook';
  static const String forgotPassword = '$auth/forgot-password';
  static const String verifyOtp = '$auth/verify-otp';
  static const String resetPassword = '$auth/reset-password';
  static const String changePassword = '$auth/change-password';

  // User endpoints
  static const String users = '/users';
  static const String userMe = '$users/me';
  static const String userProfile = '$users/profile';
  static const String userSettings = '$users/me/settings';
  static const String userAvatar = '$users/me/avatar';

  // Book endpoints
  static const String books = '/books';
  static const String booksSearch = '$books/search';
  static const String booksIsbn = '$books/isbn';

  // User Book endpoints (user's library)
  static const String userBooks = '/user-books';

  // Note endpoints
  static const String notes = '/notes';
  static const String notesSearch = '$notes/search';

  // Flashcard endpoints
  static const String flashcards = '/flashcards';
  static const String flashcardsDue = '$flashcards/due';
  static const String flashcardsStats = '$flashcards/stats';
  static const String flashcardsDecks = '$flashcards/decks';
  static const String flashcardReview = '$flashcards/review';

  // Friend endpoints
  static const String friends = '/friends';
  static const String friendsRequest = '$friends/request';
  static const String friendsSuggestions = '$friends/suggestions';

  // Activity/Feed endpoints
  static const String activities = '/activities';
  static const String activitiesFeed = '$activities/feed';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String notificationsSettings = '$notifications/settings';
  static const String notificationsRead = '$notifications/read';

  // Reading Progress endpoints
  static const String readingProgress = '/reading-progress';

  // Key Takeaway endpoints
  static const String keyTakeaways = '/key-takeaways';

  // Home endpoints
  static const String home = '/home';
  static const String homeStats = '$home/stats';

  // File upload endpoint
  static const String upload = '/upload';
}

/// Extension to build full URLs
extension ApiEndpointsExtension on ApiEndpoints {
  static String fullUrl(String endpoint) {
    return '${EnvironmentConfig.current.fullApiUrl}$endpoint';
  }
}
