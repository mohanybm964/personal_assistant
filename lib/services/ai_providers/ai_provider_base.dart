/// A single past message, used to give the provider conversation context.
class AIContextMessage {
  final String role; // "user" | "assistant" | "system"
  final String content;
  AIContextMessage(this.role, this.content);
}

/// Every AI backend (OpenAI, Gemini, Anthropic, Ollama) implements this
/// same simple contract, so the rest of the app never needs to know which
/// provider is actually answering.
abstract class AIProviderBase {
  /// Human readable name, e.g. "ChatGPT (OpenAI)"
  String get name;

  /// Whether this provider needs an internet connection.
  bool get requiresInternet;

  /// Sends [history] (including the latest user message at the end) and
  /// returns the assistant's reply as plain text / markdown.
  ///
  /// [apiKey] is null for local providers like Ollama.
  /// [model] is the specific model id to use, e.g. "gpt-4o-mini" or "llama3".
  /// [systemPrompt] lets us inject the "Jarvis" persona.
  Future<String> sendMessage({
    required List<AIContextMessage> history,
    required String model,
    String? apiKey,
    String? systemPrompt,
  });
}

class AIProviderException implements Exception {
  final String message;
  AIProviderException(this.message);
  @override
  String toString() => message;
}
