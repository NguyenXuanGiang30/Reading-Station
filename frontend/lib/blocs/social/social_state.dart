import 'package:equatable/equatable.dart';

abstract class SocialState extends Equatable {
  const SocialState();

  @override
  List<Object?> get props => [];
}

class SocialInitial extends SocialState {}

class SocialLoading extends SocialState {}

class FriendsLoaded extends SocialState {
  final List<Map<String, dynamic>> friends;
  final List<Map<String, dynamic>> pendingRequests;

  const FriendsLoaded({required this.friends, required this.pendingRequests});

  @override
  List<Object?> get props => [friends, pendingRequests];
}

class SocialError extends SocialState {
  final String message;
  const SocialError(this.message);
  @override
  List<Object?> get props => [message];
}

class UsersSearchResults extends SocialState {
  final List<Map<String, dynamic>> users;
  const UsersSearchResults(this.users);
  @override
  List<Object?> get props => [users];
}

class SocialOperationSuccess extends SocialState {
  final String message;
  const SocialOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class SocialOperationFailure extends SocialState {
  final String message;
  const SocialOperationFailure(this.message);
  @override
  List<Object?> get props => [message];
}
