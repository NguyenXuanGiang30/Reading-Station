/// AuthBloc - Manages authentication state
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final ApiService _apiService;
  
  static const String _onboardingKey = 'hasSeenOnboarding';
  
  AuthBloc({
    AuthService? authService,
    ApiService? apiService,
  })  : _authService = authService ?? AuthService(),
        _apiService = apiService ?? ApiService(),
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
    on<AuthFacebookLoginRequested>(_onFacebookLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthProfileUpdateRequested>(_onProfileUpdateRequested);
  }
  
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;
      
      // Check if user has token
      final hasToken = await _apiService.hasToken();
      
      if (!hasSeenOnboarding) {
        emit(const AuthFirstTime());
        return;
      }
      
      if (!hasToken) {
        emit(const AuthUnauthenticated());
        return;
      }
      
      // Verify token by fetching user profile
      final user = await _authService.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        await _apiService.clearTokens();
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }
  
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      final user = await _authService.login(event.email, event.password);
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Email hoặc mật khẩu không đúng'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      final user = await _authService.loginWithGoogle();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        // User cancelled - go back to unauthenticated
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  Future<void> _onFacebookLoginRequested(
    AuthFacebookLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      final user = await _authService.loginWithFacebook();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        // User cancelled - go back to unauthenticated
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      final user = await _authService.register(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
      );
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Đăng ký thất bại. Vui lòng thử lại.'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
  
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.logout();
    emit(const AuthUnauthenticated());
  }
  
  Future<void> _onProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) return;
    
    final currentUser = (state as AuthAuthenticated).user;
    
    try {
      final updatedUser = await _authService.updateProfile(
        fullName: event.fullName,
        bio: event.bio,
        avatarUrl: event.avatarUrl,
      );
      
      if (updatedUser != null) {
        emit(AuthAuthenticated(updatedUser));
      } else {
        // Keep current user if update fails
        emit(AuthAuthenticated(currentUser));
      }
    } catch (e) {
      emit(AuthAuthenticated(currentUser));
    }
  }
  
  /// Mark onboarding as seen
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
  
  /// Reset onboarding (for settings)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }
}
