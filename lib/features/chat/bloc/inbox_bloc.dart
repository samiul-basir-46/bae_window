import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/features/chat/bloc/inbox_event.dart';
import 'package:bea_window_app/features/chat/bloc/inbox_state.dart';
import 'package:bea_window_app/features/chat/models/conversation_model.dart';
import 'package:bea_window_app/features/chat/models/user_model.dart';
import 'package:bea_window_app/features/chat/repositories/chat_repository.dart';
import 'package:bea_window_app/helpers/di.dart';

class InboxBloc extends Bloc<InboxEvent, InboxState> {
  final ChatRepository _chatRepository = locator<ChatRepository>();
  StreamSubscription<List<ConversationModel>>? _conversationsSub;
  StreamSubscription<List<UserModel>>? _usersSub;
  
  final Map<String, UserModel> _resolvedUsers = {};
  final Map<String, StreamSubscription<UserModel>> _presenceSubs = {};

  InboxBloc() : super(InboxInitial()) {
    on<LoadInboxConversationsEvent>(_onLoadInboxConversations);
    on<UpdateConversationsEvent>(_onUpdateConversations);
    on<LoadUsersListEvent>(_onLoadUsersList);
    on<UpdateUsersListEvent>(_onUpdateUsersList);
    on<SearchUsersEvent>(_onSearchUsers);
  }

  Future<void> _onLoadInboxConversations(
    LoadInboxConversationsEvent event,
    Emitter<InboxState> emit,
  ) async {
    emit(InboxLoading());
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      emit(const InboxError('User is not authenticated.'));
      return;
    }

    await _conversationsSub?.cancel();
    _conversationsSub = _chatRepository
        .getConversationsStream(currentUser.uid)
        .listen((conversations) {
      add(UpdateConversationsEvent(conversations));
    }, onError: (err) {
      // Note: onError in a stream listener also can't call emit directly.
      // For now, we log the error. A dedicated error event could be added if needed.
      print('[InboxBloc] Conversations stream error: $err');
    });
  }

  Future<void> _onUpdateConversations(
    UpdateConversationsEvent event,
    Emitter<InboxState> emit,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final updatedConversations = <ConversationModel>[];
    final missingUserIds = <String>{};

    for (final conv in event.conversations) {
      final partnerUid = conv.participants.firstWhere(
        (uid) => uid != currentUser.uid,
        orElse: () => '',
      );

      if (partnerUid.isNotEmpty) {
        if (_resolvedUsers.containsKey(partnerUid)) {
          updatedConversations.add(conv.copyWith(otherUser: _resolvedUsers[partnerUid]));
          _subscribeToPresence(partnerUid);
        } else {
          missingUserIds.add(partnerUid);
          updatedConversations.add(conv); // Add without user details initially
        }
      } else {
        updatedConversations.add(conv);
      }
    }

    List<UserModel> otherUsers = event.otherUsers ?? [];
    List<UserModel> filteredUsers = event.filteredUsers ?? [];
    if (state is InboxLoaded) {
      final currentState = state as InboxLoaded;
      if (event.otherUsers == null) {
        otherUsers = currentState.otherUsers;
      }
      if (event.filteredUsers == null) {
        filteredUsers = currentState.filteredUsers;
      }
    }

    emit(InboxLoaded(
      conversations: updatedConversations,
      otherUsers: otherUsers,
      filteredUsers: filteredUsers,
    ));

    // Asynchronously resolve missing user details
    if (missingUserIds.isNotEmpty) {
      for (final uid in missingUserIds) {
        final profile = await _chatRepository.getUserProfile(uid);
        if (profile != null) {
          _resolvedUsers[uid] = profile;
          _subscribeToPresence(uid);
        }
      }
      
      // Re-emit with the newly resolved users
      final fullyResolved = event.conversations.map((conv) {
        final partnerUid = conv.participants.firstWhere(
          (uid) => uid != currentUser.uid,
          orElse: () => '',
        );
        return conv.copyWith(otherUser: _resolvedUsers[partnerUid]);
      }).toList();

      if (!isClosed) {
        emit(InboxLoaded(
          conversations: fullyResolved,
          otherUsers: otherUsers,
          filteredUsers: filteredUsers,
        ));
      }
    }
  }

  void _subscribeToPresence(String userId) {
    if (_presenceSubs.containsKey(userId)) return;

    _presenceSubs[userId] = _chatRepository.watchUserProfile(userId).listen((user) {
      _resolvedUsers[userId] = user;
      
      if (state is InboxLoaded && !isClosed) {
        final currentState = state as InboxLoaded;
        final updated = currentState.conversations.map((conv) {
          if (conv.participants.contains(userId)) {
            return conv.copyWith(otherUser: user);
          }
          return conv;
        }).toList();

        final updatedUsersList = currentState.otherUsers.map((u) {
          return u.uid == userId ? user : u;
        }).toList();

        final updatedFilteredList = currentState.filteredUsers.map((u) {
          return u.uid == userId ? user : u;
        }).toList();

        add(UpdateConversationsEvent(
          updated,
          otherUsers: updatedUsersList,
          filteredUsers: updatedFilteredList,
        ));
      }
    });
  }

  Future<void> _onLoadUsersList(
    LoadUsersListEvent event,
    Emitter<InboxState> emit,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await _usersSub?.cancel();
    _usersSub = _chatRepository.getAllUsersStream(currentUser.uid).listen((users) {
      if (!isClosed) {
        add(UpdateUsersListEvent(users));
      }
    });
  }

  void _onUpdateUsersList(
    UpdateUsersListEvent event,
    Emitter<InboxState> emit,
  ) {
    if (state is InboxLoaded) {
      final currentState = state as InboxLoaded;
      emit(InboxLoaded(
        conversations: currentState.conversations,
        otherUsers: event.users,
        filteredUsers: event.users,
      ));
    }
  }

  void _onSearchUsers(
    SearchUsersEvent event,
    Emitter<InboxState> emit,
  ) {
    if (state is InboxLoaded) {
      final currentState = state as InboxLoaded;
      if (event.query.isEmpty) {
        emit(currentState.copyWith(filteredUsers: currentState.otherUsers));
      } else {
        final filtered = currentState.otherUsers.where((u) {
          return u.name.toLowerCase().contains(event.query.toLowerCase()) ||
              (u.nickname?.toLowerCase().contains(event.query.toLowerCase()) ?? false);
        }).toList();
        emit(currentState.copyWith(filteredUsers: filtered));
      }
    }
  }

  @override
  Future<void> close() {
    _conversationsSub?.cancel();
    _usersSub?.cancel();
    for (final sub in _presenceSubs.values) {
      sub.cancel();
    }
    return super.close();
  }
}
