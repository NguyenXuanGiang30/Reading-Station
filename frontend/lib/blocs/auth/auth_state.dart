/// Auth States for AuthBloc
library;

import 'package:equatable/equatable.dart';
import '../../models/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state - unknown auth status
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state - checking auth or logging in
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state with user data
class AuthAuthenticated extends AuthState {
  final User user;
  
  const AuthAuthenticated(this.user);
  
  @override
  List<Object?> get props => [user];
}

/// Unauthenticated state
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// First time user - show onboarding
class AuthFirstTime extends AuthState {
  const AuthFirstTime();
}

/// Auth error state
class AuthError extends AuthState {
  final String message;
  
  const AuthError(this.message);
  
  @override
  List<Object?> get props => [message];
}
