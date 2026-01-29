/// API Configuration
library;

class ApiConfig {
  // Base URL for API
  static const String baseUrl = 'https://api.tuyendungvn.id.vn';
  
  // API Version
  static const String apiVersion = '/api/v1';
  
  // Full API URL
  static String get apiUrl => '$baseUrl$apiVersion';
  
  // Endpoints
  static const String auth = '/auth';
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String googleLogin = '$auth/google';
  static const String facebookLogin = '$auth/facebook';
  
  static const String users = '/users';
  static const String userMe = '$users/me';
  
  static const String books = '/books';
  static const String booksSearch = '$books/search';
  static const String booksIsbn = '$books/isbn';
  
  static const String userBooks = '/user-books';
  
  static const String notes = '/notes';
  static const String notesSearch = '$notes/search';
  
  static const String flashcards = '/flashcards';
  static const String flashcardsDue = '$flashcards/due';
  static const String flashcardsStats = '$flashcards/stats';
  static const String flashcardsDecks = '$flashcards/decks';
  
  static const String friends = '/friends';
  static const String friendsRequest = '$friends/request';
  
  static const String activities = '/activities';
  static const String activitiesFeed = '$activities/feed';
  
  static const String notifications = '/notifications';
  static const String notificationsSettings = '$notifications/settings';
  
  // Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
