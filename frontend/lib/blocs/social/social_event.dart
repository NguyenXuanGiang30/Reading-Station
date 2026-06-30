import 'package:equatable/equatable.dart';

abstract class SocialEvent extends Equatable {
  const SocialEvent();

  @override
  List<Object?> get props => [];
}

class LoadFriendsRequested extends SocialEvent {}

class SearchUsersRequested extends SocialEvent {
  final String query;
  const SearchUsersRequested(this.query);
  @override
  List<Object?> get props => [query];
}

class SendFriendRequestRequested extends SocialEvent {
  final String userId;
  const SendFriendRequestRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AcceptFriendRequestRequested extends SocialEvent {
  final String requestId;
  const AcceptFriendRequestRequested(this.requestId);
  @override
  List<Object?> get props => [requestId];
}

class RejectFriendRequestRequested extends SocialEvent {
  final String requestId;
  const RejectFriendRequestRequested(this.requestId);
  @override
  List<Object?> get props => [requestId];
}

class RemoveFriendRequested extends SocialEvent {
  final String friendId;
  const RemoveFriendRequested(this.friendId);
  @override
  List<Object?> get props => [friendId];
}
