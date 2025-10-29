import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:whitenoise/domain/services/draft_message_service.dart';

class MockDraftMessageService extends DraftMessageService {
  String? draftToReturn;
  final List<String> savedDrafts = [];
  final List<String> clearedChats = [];

  @override
  Future<String?> loadDraft({required String chatId, FlutterSecureStorage? storage}) async {
    return draftToReturn;
  }

  @override
  Future<void> saveDraft({
    required String chatId,
    required String message,
    FlutterSecureStorage? storage,
  }) async {
    savedDrafts.add(message);
    draftToReturn = message;
  }

  @override
  Future<void> clearDraft({required String chatId, FlutterSecureStorage? storage}) async {
    clearedChats.add(chatId);
    draftToReturn = null;
  }

  void reset() {
    savedDrafts.clear();
    clearedChats.clear();
    draftToReturn = null;
  }
}
