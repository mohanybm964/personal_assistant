import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider_base.dart';

class OpenAIProvider extends AIProviderBase {
  @override
  String get name => 'ChatGPT (OpenAI)';

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
          'No OpenAI API key set. Add one in Settings > AI Providers.');
    }

    final messages = <Map<String, String>>[
      if (systemPrompt != null) {'role': 'system', 'content': systemPrompt},
      ...history.map((m) => {'role': m.role, 'content': m.content}),
    ];

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
      }),
    );

    if (response.statusCode != 200) {
      throw AIProviderException(
          'OpenAI error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }
}
