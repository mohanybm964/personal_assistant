import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider_base.dart';

/// Talks to a local Ollama server (https://ollama.com).
///
/// On Desktop (Windows/macOS/Linux) this is typically:
///   http://127.0.0.1:11434   (Ollama running on the same machine)
///
/// On Android/iOS, the OS cannot run Ollama's native binary itself, so this
/// should point at Ollama running on your PC/home-server, reachable over
/// the same Wi-Fi/LAN, e.g. http://192.168.1.20:11434
class OllamaProvider extends AIProviderBase {
  final String baseUrl;
  OllamaProvider({required this.baseUrl});

  @override
  String get name => 'Ollama (Local / Offline)';

  @override
  bool get requiresInternet => false;

  @override
  Future<String> sendMessage({
    required List<AIContextMessage> history,
    required String model,
    String? apiKey,
    String? systemPrompt,
  }) async {
    final messages = <Map<String, String>>[
      if (systemPrompt != null) {'role': 'system', 'content': systemPrompt},
      ...history.map((m) => {'role': m.role, 'content': m.content}),
    ];

    late http.Response response;
    try {
      response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'stream': false,
        }),
      );
    } catch (e) {
      throw AIProviderException(
          'Could not reach Ollama at $baseUrl. Is Ollama running? ($e)');
    }

    if (response.statusCode != 200) {
      throw AIProviderException(
          'Ollama error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['message']['content'] as String;
  }

  /// Lists models already pulled/installed locally.
  Future<List<String>> listLocalModels() async {
    final response = await http.get(Uri.parse('$baseUrl/api/tags'));
    if (response.statusCode != 200) {
      throw AIProviderException('Could not list local models.');
    }
    final data = jsonDecode(response.body);
    final models = (data['models'] as List)
        .map((m) => m['name'] as String)
        .toList();
    return models;
  }

  /// Pulls (downloads) a model from the Ollama library, e.g. "llama3",
  /// "mistral", "phi3", "gemma2". Streams progress percentages back via
  /// [onProgress] so the UI can show a download bar.
  Stream<double> pullModel(String modelName) async* {
    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/api/pull'),
    );
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({'name': modelName, 'stream': true});

    final client = http.Client();
    final streamedResponse = await client.send(request);

    if (streamedResponse.statusCode != 200) {
      client.close();
      throw AIProviderException(
          'Failed to start download for $modelName (server not reachable?)');
    }

    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line);
          final total = json['total'];
          final completed = json['completed'];
          if (total != null && completed != null && total > 0) {
            yield (completed / total).clamp(0.0, 1.0) * 1.0;
          } else if (json['status'] == 'success') {
            yield 1.0;
          }
        } catch (_) {
          // ignore malformed / partial JSON lines
        }
      }
    }
    client.close();
  }

  /// Deletes a locally downloaded model to free up disk space.
  Future<void> deleteModel(String modelName) async {
    final request = http.Request('DELETE', Uri.parse('$baseUrl/api/delete'));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({'name': modelName});
    final client = http.Client();
    final response = await client.send(request);
    if (response.statusCode != 200) {
      throw AIProviderException('Failed to delete model $modelName');
    }
    client.close();
  }
}
