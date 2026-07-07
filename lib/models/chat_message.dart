import 'package:hive/hive.dart';

part 'chat_message.g.dart';

/// Role of a message inside a conversation.
enum MessageRole { user, assistant, system }

/// A single chat message. Stored locally on-device via Hive — never sent
/// to any cloud storage. Only the message *content* is sent to whichever
/// AI provider is selected, exactly like calling that provider's API directly.
@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String conversationId;

  @HiveField(2)
  String role; // stores MessageRole.name

  @HiveField(3)
  String content;

  @HiveField(4)
  DateTime timestamp;

  @HiveField(5)
  String providerUsed; // e.g. "openai", "gemini", "anthropic", "ollama"

  @HiveField(6)
  String modelUsed; // e.g. "gpt-4o", "gemini-1.5-pro", "llama3"

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.providerUsed = '',
    this.modelUsed = '',
  });

  MessageRole get roleEnum => MessageRole.values.firstWhere(
        (e) => e.name == role,
        orElse: () => MessageRole.user,
      );
}

/// A conversation groups many ChatMessages together (like a chat "thread").
@HiveType(typeId: 1)
class Conversation extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
}
