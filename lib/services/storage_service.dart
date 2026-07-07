import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/chat_message.dart';
import '../models/ai_provider_config.dart';

/// StorageService is the single source of truth for anything that must
/// persist ON THE DEVICE ONLY:
///   - Chat messages & conversations  -> Hive (local NoSQL DB, encrypted box)
///   - API keys                       -> flutter_secure_storage
///     (Keychain on iOS/macOS, Keystore on Android, DPAPI on Windows,
///      encrypted file on Linux, localStorage-with-encryption on Web)
///
/// Nothing in this file ever talks to a network. No cloud sync of any kind.
class StorageService {
  static const _messagesBox = 'chat_messages';
  static const _conversationsBox = 'conversations';
  static const _settingsBox = 'app_settings';

  final _secureStorage = const FlutterSecureStorage();

  late Box<ChatMessage> messagesBox;
  late Box<Conversation> conversationsBox;
  late Box settingsBox;

  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ConversationAdapter());
    }

    messagesBox = await Hive.openBox<ChatMessage>(_messagesBox);
    conversationsBox = await Hive.openBox<Conversation>(_conversationsBox);
    settingsBox = await Hive.openBox(_settingsBox);
  }

  // ---------------- API KEYS (secure, on-device) ----------------

  Future<void> saveApiKey(AIProviderType provider, String apiKey) async {
    await _secureStorage.write(key: 'api_key_${provider.name}', value: apiKey);
  }

  Future<String?> getApiKey(AIProviderType provider) async {
    return _secureStorage.read(key: 'api_key_${provider.name}');
  }

  Future<void> deleteApiKey(AIProviderType provider) async {
    await _secureStorage.delete(key: 'api_key_${provider.name}');
  }

  // ---------------- CONVERSATIONS ----------------

  List<Conversation> getAllConversations() {
    final list = conversationsBox.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<void> saveConversation(Conversation c) async {
    await conversationsBox.put(c.id, c);
  }

  Future<void> deleteConversation(String conversationId) async {
    await conversationsBox.delete(conversationId);
    final keysToDelete = messagesBox.values
        .where((m) => m.conversationId == conversationId)
        .map((m) => m.key)
        .toList();
    await messagesBox.deleteAll(keysToDelete);
  }

  // ---------------- MESSAGES ----------------

  List<ChatMessage> getMessages(String conversationId) {
    final list = messagesBox.values
        .where((m) => m.conversationId == conversationId)
        .toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  Future<void> saveMessage(ChatMessage msg) async {
    await messagesBox.put(msg.id, msg);
  }

  Future<void> clearAllChatHistory() async {
    await messagesBox.clear();
    await conversationsBox.clear();
  }

  // ---------------- SETTINGS ----------------

  Future<void> saveSetting(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return settingsBox.get(key, defaultValue: defaultValue) as T?;
  }
}
