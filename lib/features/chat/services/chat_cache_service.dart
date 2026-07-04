import 'package:get_storage/get_storage.dart';

class ChatCacheService {
  final GetStorage _storage = GetStorage();

  static const String _draftPrefix = 'chat_draft_';

  /// Caches the current text draft for a conversation
  void saveMessageDraft(String conversationId, String draft) {
    _storage.write('$_draftPrefix$conversationId', draft);
  }

  /// Retrieves the cached text draft
  String getMessageDraft(String conversationId) {
    return _storage.read<String>('$_draftPrefix$conversationId') ?? '';
  }

  /// Clears the draft cache
  void clearMessageDraft(String conversationId) {
    _storage.remove('$_draftPrefix$conversationId');
  }
}
