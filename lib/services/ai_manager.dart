import '../models/ai_provider_config.dart';
import 'ai_providers/ai_provider_base.dart';
import 'ai_providers/openai_provider.dart';
import 'ai_providers/gemini_provider.dart';
import 'ai_providers/anthropic_provider.dart';
import 'ai_providers/ollama_provider.dart';
import 'storage_service.dart';

/// The "Jarvis" persona/system-prompt. This is sent as a system message to
/// whichever backend model is active, so the personality stays consistent
/// no matter which AI (GPT / Gemini / Claude / a local Ollama model) is
/// actually generating the reply.
const String kJarvisSystemPrompt = '''
You are JARVIS, a highly capable, calm, witty and extremely knowledgeable personal AI assistant, 
in the style of the AI from Iron Man. You address the user respectfully (e.g. "Sir" or by name if given), 
you are concise but thorough, and you are fluent in every human language, switching fluidly to whichever 
language the user writes in. You can discuss any topic: science, code, history, everyday life, and more. 
You are confident, occasionally dryly humorous, unfailingly loyal and helpful, and you never pretend to 
have capabilities you don't have (e.g. you cannot control real-world hardware unless the app explicitly 
provides that capability). Keep answers well-structured and easy to read on a mobile screen.
''';

class AIManager {
  static final AIManager instance = AIManager._internal();
  AIManager._internal();

  final _openAI = OpenAIProvider();
  final _gemini = GeminiProvider();
  final _anthropic = AnthropicProvider();

  AIProviderBase _providerFor(AIProviderType type, String ollamaBaseUrl) {
    switch (type) {
      case AIProviderType.openai:
        return _openAI;
      case AIProviderType.gemini:
        return _gemini;
      case AIProviderType.anthropic:
        return _anthropic;
      case AIProviderType.ollama:
        return OllamaProvider(baseUrl: ollamaBaseUrl);
    }
  }

  Future<String> ask({
    required ProviderSettings settings,
    required List<AIContextMessage> history,
  }) async {
    final type = settings.activeProvider;
    final provider = _providerFor(type, settings.ollamaBaseUrl);
    final model = settings.selectedModel[type]!;

    String? apiKey;
    if (type.requiresApiKey) {
      apiKey = await StorageService.instance.getApiKey(type);
    }

    return provider.sendMessage(
      history: history,
      model: model,
      apiKey: apiKey,
      systemPrompt: kJarvisSystemPrompt,
    );
  }

  OllamaProvider ollamaFor(String baseUrl) => OllamaProvider(baseUrl: baseUrl);
}
