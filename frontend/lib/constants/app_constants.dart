/// App Constants - Centralized constants for the application
library;

/// App-wide constants
class AppConstants {
  AppConstants._();
  
  /// App name
  static const String appName = 'Trạm Đọc';
  static const String appVersion = '1.0.0';
  
  /// API timeouts (in milliseconds)
  static const int apiConnectTimeout = 30000;
  static const int apiReceiveTimeout = 30000;
  
  /// Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  /// Cache durations
  static const int cacheShortMinutes = 5;
  static const int cacheLongHours = 24;
  
  /// Validation limits
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int maxBioLength = 500;
  static const int maxTitleLength = 200;
  static const int maxDescriptionLength = 2000;
  
  /// File upload
  static const int maxFileSizeMb = 10;
  static const int maxImageSizeMb = 5;
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedDocumentExtensions = ['pdf', 'doc', 'docx'];
}

/// Animation durations
class AnimationDurations {
  AnimationDurations._();
  
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
}

/// Spacing constants
class AppSpacing {
  AppSpacing._();
  
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius constants
class AppRadius {
  AppRadius._();
  
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}

/// Icon sizes
class IconSizes {
  IconSizes._();
  
  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
}

/// Font sizes
class FontSizes {
  FontSizes._();
  
  static const double xs = 10.0;
  static const double sm = 12.0;
  static const double md = 14.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

/// Route names
class RouteNames {
  RouteNames._();
  
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/';
  static const String library = '/library';
  static const String profile = '/profile';
  static const String social = '/social';
  static const String review = '/review';
  static const String bookDetail = '/book/:id';
  static const String addBook = '/book/add';
  static const String editBook = '/book/:id/edit';
  static const String noteEditor = '/note/:id';
  static const String flashcardSession = '/flashcard/session';
  static const String settings = '/settings';
}

/// Storage keys
class StorageKeys {
  StorageKeys._();
  
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String themeMode = 'theme_mode';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String lastSyncTime = 'last_sync_time';
}

/// Error messages
class ErrorMessages {
  ErrorMessages._();
  
  static const String networkError = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.';
  static const String serverError = 'Đã xảy ra lỗi máy chủ. Vui lòng thử lại sau.';
  static const String unknownError = 'Đã xảy ra lỗi không mong muốn.';
  static const String sessionExpired = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
  static const String validationError = 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
  static const String unauthorized = 'Bạn không có quyền thực hiện thao tác này.';
  static const String notFound = 'Không tìm thấy dữ liệu.';
  static const String fileTooLarge = 'File quá lớn. Vui lòng chọn file nhỏ hơn.';
  static const String invalidFileType = 'Định dạng file không được hỗ trợ.';
}

/// Success messages
class SuccessMessages {
  SuccessMessages._();
  
  static const String loginSuccess = 'Đăng nhập thành công!';
  static const String registerSuccess = 'Đăng ký thành công!';
  static const String logoutSuccess = 'Đăng xuất thành công!';
  static const String saveSuccess = 'Lưu thành công!';
  static const String deleteSuccess = 'Xóa thành công!';
  static const String updateSuccess = 'Cập nhật thành công!';
  static const String passwordChanged = 'Đổi mật khẩu thành công!';
  static const String emailSent = 'Email đã được gửi!';
}

/// Validation messages
class ValidationMessages {
  ValidationMessages._();
  
  static const String required = 'Trường này là bắt buộc';
  static const String emailInvalid = 'Email không hợp lệ';
  static const String passwordTooShort = 'Mật khẩu phải có ít nhất 8 ký tự';
  static const String passwordMismatch = 'Mật khẩu không khớp';
  static const String nameTooShort = 'Tên phải có ít nhất 2 ký tự';
  static const String nameTooLong = 'Tên không được vượt quá 100 ký tự';
}
