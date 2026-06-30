/// API Configuration
/// Now uses EnvironmentConfig for flexible environment switching
library;

import 'environment.dart';

class ApiConfig {
  // Use environment config for base URL
  static String get baseUrl => EnvironmentConfig.current.apiBaseUrl;
  static String get apiVersion => EnvironmentConfig.current.apiVersion;
  static String get apiUrl => EnvironmentConfig.current.fullApiUrl;
  
  // Timeouts from environment config
  static int get connectTimeout => EnvironmentConfig.current.connectTimeout;
  static int get receiveTimeout => EnvironmentConfig.current.receiveTimeout;
  
  // Enable logging based on environment
  static bool get enableLogging => EnvironmentConfig.current.enableLogging;

  // Endpoints - using ApiEndpoints class for consistency
  // Auth endpoints
  static const String auth = ApiEndpoints.auth;
  static const String login = ApiEndpoints.login;
  static const String register = ApiEndpoints.register;
  static const String logout = ApiEndpoints.logout;
  static const String refreshToken = ApiEndpoints.refreshToken;
  static const String googleLogin = ApiEndpoints.googleLogin;
  static const String facebookLogin = ApiEndpoints.facebookLogin;
  static const String forgotPassword = ApiEndpoints.forgotPassword;
  static const String verifyOtp = ApiEndpoints.verifyOtp;
  static const String resetPassword = ApiEndpoints.resetPassword;
  static const String changePassword = ApiEndpoints.changePassword;
  
  // User endpoints
  static const String users = ApiEndpoints.users;
  static const String userMe = ApiEndpoints.userMe;
  static const String userProfile = ApiEndpoints.userProfile;
  static const String userSettings = ApiEndpoints.userSettings;
  static const String userAvatar = ApiEndpoints.userAvatar;
  
  // Book endpoints
  static const String books = ApiEndpoints.books;
  static const String booksSearch = ApiEndpoints.booksSearch;
  static const String booksIsbn = ApiEndpoints.booksIsbn;
  
  // User Book endpoints
  static const String userBooks = ApiEndpoints.userBooks;
  
  // Note endpoints
  static const String notes = ApiEndpoints.notes;
  static const String notesSearch = ApiEndpoints.notesSearch;
  
  // Flashcard endpoints
  static const String flashcards = ApiEndpoints.flashcards;
  static const String flashcardsDue = ApiEndpoints.flashcardsDue;
  static const String flashcardsStats = ApiEndpoints.flashcardsStats;
  static const String flashcardsDecks = ApiEndpoints.flashcardsDecks;
  static const String flashcardReview = ApiEndpoints.flashcardReview;
  
  // Friend endpoints
  static const String friends = ApiEndpoints.friends;
  static const String friendsRequest = ApiEndpoints.friendsRequest;
  static const String friendsSuggestions = ApiEndpoints.friendsSuggestions;
  
  // Activity/Feed endpoints
  static const String activities = ApiEndpoints.activities;
  static const String activitiesFeed = ApiEndpoints.activitiesFeed;
  
  // Notification endpoints
  static const String notifications = ApiEndpoints.notifications;
  static const String notificationsSettings = ApiEndpoints.notificationsSettings;
  static const String notificationsRead = ApiEndpoints.notificationsRead;
  
  // Reading Progress endpoints
  static const String readingProgress = ApiEndpoints.readingProgress;
  
  // Key Takeaway endpoints
  static const String keyTakeaways = ApiEndpoints.keyTakeaways;
  
  // Home endpoints
  static const String home = ApiEndpoints.home;
  static const String homeStats = ApiEndpoints.homeStats;
  
  // File upload endpoint
  static const String upload = ApiEndpoints.upload;
}
