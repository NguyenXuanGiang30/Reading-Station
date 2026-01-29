/// Auth Service - Handles authentication API calls
library;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'package:dio/dio.dart';

class AuthService {
  final ApiService _apiService;
  
  // Google Sign-In configuration
  // Web Client ID from Google Cloud Console
  static const String _googleWebClientId = 
      '844562415563-8lketaadahovtrhfa14pkirq6gs6v2nv.apps.googleusercontent.com';
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: _googleWebClientId,
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
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        // Save token
        final token = data['token'] ?? data['accessToken'];
        if (token != null) {
          await _apiService.saveToken(token);
        }
        
        // Parse user
        final userData = data['user'] ?? data;
        return User.fromJson(userData);
      }
      return null;
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
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        // Save token
        final token = data['token'] ?? data['accessToken'];
        if (token != null) {
          await _apiService.saveToken(token);
        }
        
        // Parse user
        final userData = data['user'] ?? data;
        return User.fromJson(userData);
      }
      return null;
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
      );
      
      if (result.status != LoginStatus.success) {
        if (result.status == LoginStatus.cancelled) {
          return null; // User cancelled
        }
        throw Exception(result.message ?? 'Facebook login failed');
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
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        // Save token
        final token = data['token'] ?? data['accessToken'];
        if (token != null) {
          await _apiService.saveToken(token);
        }
        
        // Parse user
        final userData = data['user'] ?? data;
        return User.fromJson(userData);
      }
      return null;
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
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        
        // Save token if returned
        final token = data['token'] ?? data['accessToken'];
        if (token != null) {
          await _apiService.saveToken(token);
        }
        
        // Parse user
        final userData = data['user'] ?? data;
        return User.fromJson(userData);
      }
      return null;
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
        ApiConfig.userMe,
        data: data,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        return User.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Logout - clear tokens and sign out from social providers
  Future<void> logout() async {
    // Sign out from Google if signed in
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    
    // Sign out from Facebook if signed in
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
    
    await _apiService.clearTokens();
  }
}

