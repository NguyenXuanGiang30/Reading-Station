/// Auth Service - Handles authentication API calls
library;

import 'package:google_sign_in/google_sign_in.dart';
import '../exceptions/app_exception.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'package:dio/dio.dart';

class AuthService {
  final ApiService _apiService;

  // Android reads Google Sign-In config from google-services.json.
  // Web uses the client ID declared in web/index.html.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  
  AuthService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();
  
  /// Login with email and password
  Future<User?> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConfig.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      return await _handleAuthResponse(response);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('message')) {
          throw Exception(data['message']);
        }
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Login with Google OAuth
  Future<User?> loginWithGoogle() async {
    try {
      // Sign out first to ensure fresh login
      await _googleSignIn.signOut();
      
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }
      
      // Get authentication details
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      final accessToken = googleAuth.accessToken;
      
      if (accessToken == null) {
        throw Exception('Không thể lấy access token từ Google');
      }
      
      // Send access token to backend for verification
      final response = await _apiService.post(
        ApiConfig.googleLogin,
        data: {'accessToken': accessToken},
      );
      
      return await _handleAuthResponse(response);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('message')) {
          throw Exception(data['message']);
        }
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Login with Facebook OAuth
  Future<User?> loginWithFacebook() async {
    try {
      // Logout first to ensure fresh login
      await FacebookAuth.instance.logOut();
      
      // Trigger Facebook Login
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
        loginBehavior: LoginBehavior.nativeWithFallback,
      );
      
      if (result.status != LoginStatus.success) {
        if (result.status == LoginStatus.cancelled) {
          return null; // User cancelled
        }
        if (result.status == LoginStatus.operationInProgress) {
          throw Exception('Đăng nhập Facebook đang được xử lý, vui lòng thử lại.');
        }
        throw Exception(
          result.message ?? 'Đăng nhập Facebook thất bại. Hãy kiểm tra cấu hình app trên Meta Developers.',
        );
      }
      
      final accessToken = result.accessToken?.tokenString;
      
      if (accessToken == null) {
        throw Exception('Không thể lấy access token từ Facebook');
      }
      
      // Send access token to backend for verification
      final response = await _apiService.post(
        ApiConfig.facebookLogin,
        data: {'accessToken': accessToken},
      );
      
      return await _handleAuthResponse(response);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('message')) {
          throw Exception(data['message']);
        }
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Register new user
  Future<User?> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.register,
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
        },
      );
      
      return await _handleAuthResponse(response);
    } on AppException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
  
  /// Get current authenticated user
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiService.get(ApiConfig.userMe);
      
      if (response.statusCode == 200 && response.data != null) {
        return User.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on AppException {
      rethrow;
    } catch (e) {
      return null;
    }
  }
  
  /// Update user profile
  Future<User?> updateProfile({
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['fullName'] = fullName;
      if (bio != null) data['bio'] = bio;
      if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
      
      final response = await _apiService.put(
        ApiConfig.userProfile,
        data: data,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        return User.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on AppException {
      rethrow;
    } catch (e) {
      return null;
    }
  }
  
  /// Logout - clear tokens and sign out from social providers
  Future<void> logout() async {
    // Sign out from Google if signed in
    try {
      await _googleSignIn.signOut();
    } on AppException {
      rethrow;
    } catch (_) {}
    
    // Sign out from Facebook if signed in
    try {
      await FacebookAuth.instance.logOut();
    } on AppException {
      rethrow;
    } catch (_) {}
    
    await _apiService.clearTokens();
  }
  
  /// Helper method to extract token and user from auth responses
  Future<User?> _handleAuthResponse(Response response) async {
    if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      
      // Save tokens
      final token = data['token'] ?? data['accessToken'];
      if (token != null) {
        await _apiService.saveToken(token);
      }
      final refreshToken = data['refreshToken'];
      if (refreshToken != null) {
        await _apiService.saveRefreshToken(refreshToken);
      }
      
      // Parse user
      final userData = data['user'] ?? data;
      return User.fromJson(userData);
    }
    return null;
  }
}

