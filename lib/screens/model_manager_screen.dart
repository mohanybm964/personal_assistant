import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/settings_provider.dart';
import '../services/ai_providers/ollama_provider.dart';

/// Popular models available in the Ollama library (https://ollama.com/library).
/// Users can also type any custom model name/tag.
const List<Map<String, String>> kPopularOllamaModels = [
  {'name': 'llama3', 'desc': "Meta's Llama 3 — great all-rounder"},
  {'name': 'llama3.1', 'desc': "Meta's Llama 3.1"},
  {'name': 'mistral', 'desc': 'Fast, capable 7B model'},
  {'name': 'phi3', 'desc': "Microsoft's small, efficient model"},
  {'name': 'gemma2', 'desc': "Google's Gemma 2"},
  {'name': 'qwen2.5', 'desc': "Alibaba's Qwen 2.5 — strong multilingual"},
  {'name': 'codellama', 'desc': 'Specialized for code generation'},
  {'name': 'deepseek-r1', 'desc': 'Strong reasoning model'},
];

class ModelManagerScreen extends StatefulWidget {
  const ModelManagerScreen({super.key});

  @override
  State<ModelManagerScreen> createState() => _ModelManagerScreenState();
}

class _ModelManagerScreenState extends State<ModelManagerScreen> {
  List<String> _installedModels = [];
  bool _loading = true;
  String? _error;
  final Map<String, double> _downloadProgress = {};
  final _customModelController = TextEditingController();

  late OllamaProvider _ollama;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _ollama = OllamaProvider(baseUrl: settings.settings.ollamaBaseUrl);
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final models = await _ollama.listLocalModels();
      setState(() => _installedModels = models);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pull(String modelName) async {
    setState(() => _downloadProgress[modelName] = 0.0);
    try {
      await for (final progress in _ollama.pullModel(modelName)) {
        setState(() => _downloadProgress[modelName] = progress);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$modelName downloaded successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      setState(() => _downloadProgress.remove(modelName));
      _refresh();
    }
  }

  Future<void> _delete(String modelName) async {
    try {
      await _ollama.deleteModel(modelName);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Models (Ollama)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionTitle('Installed on this Ollama server'),
                    if (_installedModels.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No models downloaded yet.',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                    ..._installedModels.map((m) => Card(
                          color: AppTheme.surface,
                          child: ListTile(
                            leading: const Icon(Icons.check_circle,
                                color: Colors.greenAccent),
                            title: Text(m),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _delete(m),
                            ),
                          ),
                        )),
                    const SizedBox(height: 24),
                    _sectionTitle('Download from Ollama library'),
                    ...kPopularOllamaModels.map((model) {
                      final name = model['name']!;
                      final progress = _downloadProgress[name];
                      final alreadyInstalled =
                          _installedModels.any((m) => m.startsWith(name));
                      return Card(
                        color: AppTheme.surface,
                        child: ListTile(
                          title: Text(name),
                          subtitle: progress != null
                              ? LinearProgressIndicator(
                                  value: progress > 0 ? progress : null,
                                  color: AppTheme.accent,
                                )
                              : Text(model['desc']!,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary)),
                          trailing: alreadyInstalled
                              ? const Icon(Icons.check, color: Colors.greenAccent)
                              : IconButton(
                                  icon: const Icon(Icons.download_outlined,
                                      color: AppTheme.accent),
                                  onPressed: progress != null
                                      ? null
                                      : () => _pull(name),
                                ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    _sectionTitle('Custom model'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customModelController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. llama3:70b, mixtral, tinyllama',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final name = _customModelController.text.trim();
                            if (name.isNotEmpty) _pull(name);
                          },
                          child: const Text('Pull'),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Could not reach your Ollama server.\n\n$_error\n\n'
              'Make sure Ollama is installed and running '
              '(ollama serve), and that the address in Settings is correct.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.accent)),
      );
}
