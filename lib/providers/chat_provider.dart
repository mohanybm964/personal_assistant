import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/storage_service.dart';
import '../services/ai_manager.dart';
import '../services/ai_providers/ai_provider_base.dart';
import 'settings_provider.dart';

class ChatProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  Conversation? currentConversation;
  List<ChatMessage> messages = [];
  bool isSending = false;
  String? lastError;

  List<Conversation> get allConversations =>
      StorageService.instance.getAllConversations();

  void startNewConversation() {
    final now = DateTime.now();
    currentConversation = Conversation(
      id: _uuid.v4(),
      title: 'New chat',
      createdAt: now,
      updatedAt: now,
    );
    messages = [];
    notifyListeners();
  }

  void openConversation(Conversation c) {
    currentConversation = c;
    messages = StorageService.instance.getMessages(c.id);
    notifyListeners();
  }

  Future<void> deleteConversation(Conversation c) async {
    await StorageService.instance.deleteConversation(c.id);
    if (currentConversation?.id == c.id) {
      startNewConversation();
    }
    notifyListeners();
  }

  Future<void> sendMessage(String text, SettingsProvider settingsProvider) async {
    if (text.trim().isEmpty) return;
    currentConversation ??= () {
      startNewConversation();
      return currentConversation;
    }();

    final conv = currentConversation!;
    final now = DateTime.now();

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      conversationId: conv.id,
      role: MessageRole.user.name,
      content: text.trim(),
      timestamp: now,
    );
    messages.add(userMsg);
    await StorageService.instance.saveMessage(userMsg);

    // Auto-title the conversation from the first message.
    if (conv.title == 'New chat') {
      conv.title = text.trim().length > 40
          ? '${text.trim().substring(0, 40)}...'
          : text.trim();
    }
    conv.updatedAt = now;
    await StorageService.instance.saveConversation(conv);

    isSending = true;
    lastError = null;
    notifyListeners();

    try {
      final history = messages
          .map((m) => AIContextMessage(
              m.roleEnum == MessageRole.assistant ? 'assistant' : 'user',
              m.content))
          .toList();

      final reply = await AIManager.instance.ask(
        settings: settingsProvider.settings,
        history: history,
      );

      final assistantMsg = ChatMessage(
        id: _uuid.v4(),
        conversationId: conv.id,
        role: MessageRole.assistant.name,
        content: reply,
        timestamp: DateTime.now(),
        providerUsed: settingsProvider.settings.activeProvider.name,
        modelUsed:
            settingsProvider.settings.selectedModel[settingsProvider.settings.activeProvider] ?? '',
      );
      messages.add(assistantMsg);
      await StorageService.instance.saveMessage(assistantMsg);

      conv.updatedAt = DateTime.now();
      await StorageService.instance.saveConversation(conv);
    } catch (e) {
      lastError = e.toString();
      final errorMsg = ChatMessage(
        id: _uuid.v4(),
        conversationId: conv.id,
        role: MessageRole.assistant.name,
        content:
            "⚠️ I couldn't get a response.\n\n$lastError",
        timestamp: DateTime.now(),
      );
      messages.add(errorMsg);
      await StorageService.instance.saveMessage(errorMsg);
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> clearAllHistory() async {
    await StorageService.instance.clearAllChatHistory();
    startNewConversation();
  }
}
