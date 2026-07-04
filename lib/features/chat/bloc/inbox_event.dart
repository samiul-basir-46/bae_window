import 'package:bea_window_app/features/chat/models/conversation_model.dart';
import 'package:bea_window_app/features/chat/models/user_model.dart';

abstract class InboxEvent {
  const InboxEvent();
}

class LoadInboxConversationsEvent extends InboxEvent {}

class UpdateConversationsEvent extends InboxEvent {
  final List<ConversationModel> conversations;
  final List<UserModel>? otherUsers;
  final List<UserModel>? filteredUsers;
  const UpdateConversationsEvent(
    this.conversations, {
    this.otherUsers,
    this.filteredUsers,
  });
}

class LoadUsersListEvent extends InboxEvent {}

class UpdateUsersListEvent extends InboxEvent {
  final List<UserModel> users;
  const UpdateUsersListEvent(this.users);
}

class SearchUsersEvent extends InboxEvent {
  final String query;
  const SearchUsersEvent(this.query);
}
