import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider_base.dart';

class GeminiProvider extends AIProviderBase {
  @override
  String get name => 'Gemini (Google)';

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
          'No Gemini API key set. Add one in Settings > AI Providers.');
    }

    final contents = history
        .map((m) => {
              'role': m.role == 'assistant' ? 'model' : 'user',
              'parts': [
                {'text': m.content}
              ],
            })
        .toList();

    final body = {
      'contents': contents,
      if (systemPrompt != null)
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
    };

    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw AIProviderException(
          'Gemini error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }
}
