import 'package:flutter/foundation.dart';
import '../models/ai_provider_config.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  ProviderSettings settings = ProviderSettings.defaults();
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final store = StorageService.instance;

    final providerName =
        store.getSetting<String>('active_provider', defaultValue: 'ollama');
    settings.activeProvider = AIProviderType.values.firstWhere(
      (e) => e.name == providerName,
      orElse: () => AIProviderType.ollama,
    );

    settings.ollamaBaseUrl = store.getSetting<String>('ollama_base_url',
            defaultValue: 'http://127.0.0.1:11434') ??
        'http://127.0.0.1:11434';

    for (final type in AIProviderType.values) {
      final saved = store.getSetting<String>('model_${type.name}');
      if (saved != null) settings.selectedModel[type] = saved;
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> setActiveProvider(AIProviderType type) async {
    settings.activeProvider = type;
    await StorageService.instance.saveSetting('active_provider', type.name);
    notifyListeners();
  }

  Future<void> setModelFor(AIProviderType type, String model) async {
    settings.selectedModel[type] = model;
    await StorageService.instance.saveSetting('model_${type.name}', model);
    notifyListeners();
  }

  Future<void> setOllamaBaseUrl(String url) async {
    settings.ollamaBaseUrl = url;
    await StorageService.instance.saveSetting('ollama_base_url', url);
    notifyListeners();
  }

  Future<void> saveApiKey(AIProviderType type, String key) async {
    await StorageService.instance.saveApiKey(type, key);
    notifyListeners();
  }

  Future<String?> getApiKey(AIProviderType type) {
    return StorageService.instance.getApiKey(type);
  }

  Future<void> deleteApiKey(AIProviderType type) async {
    await StorageService.instance.deleteApiKey(type);
    notifyListeners();
  }
}
