import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/ai_provider_config.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import 'model_manager_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<AIProviderType, TextEditingController> _keyControllers = {
    AIProviderType.openai: TextEditingController(),
    AIProviderType.gemini: TextEditingController(),
    AIProviderType.anthropic: TextEditingController(),
  };
  late TextEditingController _ollamaUrlController;
  bool _keysLoaded = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _ollamaUrlController =
        TextEditingController(text: settings.settings.ollamaBaseUrl);
    _loadKeys(settings);
  }

  Future<void> _loadKeys(SettingsProvider settings) async {
    for (final type in _keyControllers.keys) {
      final key = await settings.getApiKey(type);
      _keyControllers[type]!.text = key ?? '';
    }
    setState(() => _keysLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Active AI Brain'),
          ...AIProviderType.values.map((type) => RadioListTile<AIProviderType>(
                value: type,
                groupValue: settings.settings.activeProvider,
                onChanged: (v) => settings.setActiveProvider(v!),
                title: Text(type.label),
                subtitle: Text(type.requiresInternet
                    ? 'Requires internet + API key'
                    : 'Fully offline — runs on-device / your local server'),
                activeColor: AppTheme.accent,
              )),
          const SizedBox(height: 24),
          _sectionTitle('API Keys (stored securely on this device only)'),
          if (!_keysLoaded)
            const Center(child: CircularProgressIndicator())
          else
            ...[
              AIProviderType.openai,
              AIProviderType.gemini,
              AIProviderType.anthropic,
            ].map((type) => _apiKeyField(type, settings)),
          const SizedBox(height: 24),
          _sectionTitle('Offline Mode (Ollama)'),
          Card(
            color: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Ollama server address (on Android/iOS point this at '
                      'Ollama running on your PC over Wi-Fi/LAN):'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ollamaUrlController,
                    decoration: const InputDecoration(
                      hintText: 'http://127.0.0.1:11434',
                    ),
                    onSubmitted: (v) => settings.setOllamaBaseUrl(v.trim()),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => settings
                            .setOllamaBaseUrl(_ollamaUrlController.text.trim()),
                        child: const Text('Save address'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Manage local models'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ModelManagerScreen()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Chat Data'),
          Card(
            color: AppTheme.surface,
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
              title: const Text('Clear all chat history'),
              subtitle: const Text('Deletes all conversations stored on this device.'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear all history?'),
                    content: const Text(
                        'This permanently deletes all conversations stored on this device. This cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await context.read<ChatProvider>().clearAllHistory();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat history cleared.')),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _apiKeyField(AIProviderType type, SettingsProvider settings) {
    final controller = _keyControllers[type]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type.label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Paste your ${type.label} API key',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save_outlined),
                    onPressed: () async {
                      await settings.saveApiKey(type, controller.text.trim());
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${type.label} key saved.')),
                        );
                      }
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Text('Model: ',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: settings.settings.selectedModel[type],
                        items: _modelOptions(type)
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) settings.setModelFor(type, v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _modelOptions(AIProviderType type) {
    switch (type) {
      case AIProviderType.openai:
        return ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'o3-mini'];
      case AIProviderType.gemini:
        return ['gemini-1.5-pro', 'gemini-1.5-flash', 'gemini-2.0-flash'];
      case AIProviderType.anthropic:
        return ['claude-sonnet-4-5', 'claude-opus-4-5', 'claude-haiku-4-5'];
      case AIProviderType.ollama:
        return ['llama3', 'mistral', 'phi3', 'gemma2'];
    }
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.accent)),
      );
}
