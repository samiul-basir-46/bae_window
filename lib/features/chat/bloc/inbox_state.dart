import 'package:bea_window_app/features/chat/models/conversation_model.dart';
import 'package:bea_window_app/features/chat/models/user_model.dart';

abstract class InboxState {
  const InboxState();
}

class InboxInitial extends InboxState {}

class InboxLoading extends InboxState {}

class InboxLoaded extends InboxState {
  final List<ConversationModel> conversations;
  final List<UserModel> otherUsers;
  final List<UserModel> filteredUsers;

  const InboxLoaded({
    required this.conversations,
    this.otherUsers = const [],
    this.filteredUsers = const [],
  });

  InboxLoaded copyWith({
    List<ConversationModel>? conversations,
    List<UserModel>? otherUsers,
    List<UserModel>? filteredUsers,
  }) {
    return InboxLoaded(
      conversations: conversations ?? this.conversations,
      otherUsers: otherUsers ?? this.otherUsers,
      filteredUsers: filteredUsers ?? this.filteredUsers,
    );
  }
}

class InboxError extends InboxState {
  final String message;
  const InboxError(this.message);
}
