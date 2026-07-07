import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider_base.dart';

class AnthropicProvider extends AIProviderBase {
  @override
  String get name => 'Claude (Anthropic)';

  @override
  bool get requiresInternet => true;

  @override
  Future<String> sendMessage({
    required List<AIContextMessage> history,
    required String model,
    String? apiKey,
    String? systemPrompt,
  }) async {
    if (apiKey == null || apiKey.isEmpty) {
      throw AIProviderException(
          'No Anthropic API key set. Add one in Settings > AI Providers.');
    }

    final messages = history
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': 4096,
        if (systemPrompt != null) 'system': systemPrompt,
        'messages': messages,
      }),
    );

    if (response.statusCode != 200) {
      throw AIProviderException(
          'Anthropic error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['content'][0]['text'] as String;
  }
}
