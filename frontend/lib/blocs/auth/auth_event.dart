/// Auth Events for AuthBloc
library;

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

/// Check if user is already logged in
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Login with email and password
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  
  const AuthLoginRequested({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object?> get props => [email, password];
}

/// Login with Google OAuth
class AuthGoogleLoginRequested extends AuthEvent {
  const AuthGoogleLoginRequested();
}

/// Login with Facebook OAuth
class AuthFacebookLoginRequested extends AuthEvent {
  const AuthFacebookLoginRequested();
}

/// Register new user
class AuthRegisterRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  
  const AuthRegisterRequested({
    required this.fullName,
    required this.email,
    required this.password,
  });
  
  @override
  List<Object?> get props => [fullName, email, password];
}

/// Logout
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Update user profile
class AuthProfileUpdateRequested extends AuthEvent {
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  
  const AuthProfileUpdateRequested({
    this.fullName,
    this.bio,
    this.avatarUrl,
  });
  
  @override
  List<Object?> get props => [fullName, bio, avatarUrl];
}
