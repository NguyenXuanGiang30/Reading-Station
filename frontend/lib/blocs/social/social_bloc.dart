import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/friend_service.dart';
import '../../exceptions/app_exception.dart';
import 'social_event.dart';
import 'social_state.dart';

class SocialBloc extends Bloc<SocialEvent, SocialState> {
  final FriendService _friendService;

  SocialBloc({FriendService? friendService})
      : _friendService = friendService ?? FriendService(),
        super(SocialInitial()) {
    on<LoadFriendsRequested>(_onLoadFriends);
    on<SearchUsersRequested>(_onSearchUsers);
    on<SendFriendRequestRequested>(_onSendRequest);
    on<AcceptFriendRequestRequested>(_onAcceptRequest);
    on<RejectFriendRequestRequested>(_onRejectRequest);
    on<RemoveFriendRequested>(_onRemoveFriend);
  }

  Future<void> _onLoadFriends(
      LoadFriendsRequested event, Emitter<SocialState> emit) async {
    emit(SocialLoading());
    try {
      final friends = await _friendService.getFriends();
      final pending = await _friendService.getPendingRequests();
      emit(FriendsLoaded(friends: friends, pendingRequests: pending));
    } on AppException catch (e) {
      emit(SocialError(e.message));
    } catch (e) {
      emit(SocialError('Không thể tải danh sách bạn bè: $e'));
    }
  }

  Future<void> _onSearchUsers(
      SearchUsersRequested event, Emitter<SocialState> emit) async {
    final currentState = state;
    emit(SocialLoading());
    try {
      final users = await _friendService.searchUsers(event.query);
      emit(UsersSearchResults(users));
      // Normally we might want to return to FriendsLoaded after search is cleared
    } on AppException catch (e) {
      emit(SocialError(e.message));
      if (currentState is FriendsLoaded) emit(currentState);
    } catch (e) {
      emit(SocialError('Lỗi tìm kiếm: $e'));
      if (currentState is FriendsLoaded) emit(currentState);
    }
  }

  Future<void> _onSendRequest(
      SendFriendRequestRequested event, Emitter<SocialState> emit) async {
    final currentState = state;
    emit(SocialLoading());
    try {
      await _friendService.sendFriendRequest(event.userId);
      emit(const SocialOperationSuccess('Đã gửi lời mời kết bạn'));
      if (currentState is FriendsLoaded) emit(currentState);
    } on AppException catch (e) {
      emit(SocialOperationFailure(e.message));
      if (currentState is FriendsLoaded) emit(currentState);
      if (currentState is UsersSearchResults) emit(currentState);
    } catch (e) {
      emit(SocialOperationFailure('Lỗi: $e'));
      if (currentState is FriendsLoaded) emit(currentState);
      if (currentState is UsersSearchResults) emit(currentState);
    }
  }

  Future<void> _onAcceptRequest(
      AcceptFriendRequestRequested event, Emitter<SocialState> emit) async {
    emit(SocialLoading());
    try {
      await _friendService.acceptFriendRequest(event.requestId);
      emit(const SocialOperationSuccess('Đã chấp nhận kết bạn'));
      add(LoadFriendsRequested());
    } on AppException catch (e) {
      emit(SocialOperationFailure(e.message));
      add(LoadFriendsRequested());
    } catch (e) {
      emit(SocialOperationFailure('Lỗi: $e'));
      add(LoadFriendsRequested());
    }
  }

  Future<void> _onRejectRequest(
      RejectFriendRequestRequested event, Emitter<SocialState> emit) async {
    emit(SocialLoading());
    try {
      await _friendService.rejectFriendRequest(event.requestId);
      emit(const SocialOperationSuccess('Đã từ chối kết bạn'));
      add(LoadFriendsRequested());
    } catch (e) {
      emit(const SocialOperationFailure('Lỗi từ chối kết bạn'));
      add(LoadFriendsRequested());
    }
  }

  Future<void> _onRemoveFriend(
      RemoveFriendRequested event, Emitter<SocialState> emit) async {
    emit(SocialLoading());
    try {
      await _friendService.removeFriend(event.friendId);
      emit(const SocialOperationSuccess('Đã hủy kết bạn'));
      add(LoadFriendsRequested());
    } on AppException catch (e) {
      emit(SocialOperationFailure(e.message));
      add(LoadFriendsRequested());
    } catch (e) {
      emit(SocialOperationFailure('Lỗi: $e'));
      add(LoadFriendsRequested());
    }
  }
}
