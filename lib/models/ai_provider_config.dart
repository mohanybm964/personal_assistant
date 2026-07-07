/// Which "brain" Jarvis is currently using.
enum AIProviderType { openai, gemini, anthropic, ollama }

extension AIProviderTypeX on AIProviderType {
  String get label {
    switch (this) {
      case AIProviderType.openai:
        return 'ChatGPT (OpenAI)';
      case AIProviderType.gemini:
        return 'Gemini (Google)';
      case AIProviderType.anthropic:
        return 'Claude (Anthropic)';
      case AIProviderType.ollama:
        return 'Ollama (Local / Offline)';
    }
  }

  bool get requiresApiKey => this != AIProviderType.ollama;
  bool get requiresInternet => this != AIProviderType.ollama;
}

/// Holds the currently configured model name per provider, e.g.
/// openai -> "gpt-4o-mini", gemini -> "gemini-1.5-flash", ollama -> "llama3".
class ProviderSettings {
  AIProviderType activeProvider;
  Map<AIProviderType, String> selectedModel;
  String ollamaBaseUrl; // e.g. http://127.0.0.1:11434 or http://<lan-ip>:11434

  ProviderSettings({
    required this.activeProvider,
    required this.selectedModel,
    required this.ollamaBaseUrl,
  });

  factory ProviderSettings.defaults() => ProviderSettings(
        activeProvider: AIProviderType.ollama,
        selectedModel: {
          AIProviderType.openai: 'gpt-4o-mini',
          AIProviderType.gemini: 'gemini-1.5-flash',
          AIProviderType.anthropic: 'claude-sonnet-4-5',
          AIProviderType.ollama: 'llama3',
        },
        ollamaBaseUrl: 'http://127.0.0.1:11434',
      );
}
