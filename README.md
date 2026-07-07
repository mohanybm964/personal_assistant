# Personal Assistant (JARVIS-style AI, Flutter)

A cross-platform (Android / iOS / Web / Windows / macOS / Linux) personal AI
assistant built with Flutter.

- Connects to **ChatGPT (OpenAI)**, **Gemini (Google)**, or **Claude
  (Anthropic)** using *your own* API key.
- Or runs **fully offline** using a local model pulled through **Ollama**
  (llama3, mistral, phi3, gemma2, qwen2.5, deepseek-r1, or any custom model
  in the Ollama library).
- Speaks with a **JARVIS-style persona** (calm, witty, all-knowing, multilingual)
  layered on top of whichever backend model you choose — the app injects a
  system prompt so the personality stays consistent no matter which AI answers.
- **All chat history and API keys are stored only on your device**
  (Hive local database + OS secure keystore). Nothing is uploaded to any
  server owned by this app.

> **Note on "unlimited usage":** the app itself places no artificial cap on
> messages. Actual limits (rate limits, quotas, cost) are set by whichever
> provider's API key you use (OpenAI/Google/Anthropic) — this app cannot
> override those. Ollama models running locally have no such limits since
> they run entirely on your own hardware.

---

## Project structure

```
personal_assistant/
├── pubspec.yaml
├── lib/
│   ├── main.dart                     # entry point, sets up storage + providers
│   ├── app.dart                      # root MaterialApp
│   ├── core/
│   │   ├── theme.dart                 # dark "arc reactor" theme
│   │   └── constants.dart             # app name, developer info
│   ├── models/
│   │   ├── chat_message.dart          # Hive models: ChatMessage, Conversation
│   │   ├── chat_message.g.dart        # Hive adapters (hand-written, matches build_runner output)
│   │   └── ai_provider_config.dart    # AIProviderType enum + settings model
│   ├── services/
│   │   ├── storage_service.dart       # on-device storage (Hive + secure storage)
│   │   ├── ai_manager.dart            # picks provider, injects JARVIS persona
│   │   └── ai_providers/
│   │       ├── ai_provider_base.dart
│   │       ├── openai_provider.dart
│   │       ├── gemini_provider.dart
│   │       ├── anthropic_provider.dart
│   │       └── ollama_provider.dart   # local/offline models incl. pull/delete
│   ├── providers/                     # app state (package:provider)
│   │   ├── chat_provider.dart
│   │   └── settings_provider.dart
│   ├── screens/
│   │   ├── chat_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── model_manager_screen.dart  # download/delete local Ollama models
│   │   └── about_screen.dart          # developer info
│   └── widgets/
│       ├── chat_bubble.dart
│       └── message_input.dart
└── assets/images/
```

---

## Setup

### 1. Prerequisites
- Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel).
- Run `flutter doctor` and resolve any issues for the platforms you plan to target.

### 2. Generate native platform folders
This package ships only the Dart/Flutter source (`lib/`, `pubspec.yaml`,
assets). Because `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`
folders are large, machine-generated, and toolchain/version-specific, generate
them locally with:

```bash
cd personal_assistant
flutter create . --platforms=android,ios,web,windows,macos,linux --project-name personal_assistant
```

This safely merges the native scaffolding into the existing `lib/` and
`pubspec.yaml` you already have — it will not overwrite your Dart code.

### 3. Install dependencies
```bash
flutter pub get
```

### 4. Required platform permissions

**Android** — add internet permission in `android/app/src/main/AndroidManifest.xml`
(needed for API calls and for reaching Ollama on your LAN):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

**iOS** — if you plan to reach a local Ollama server over plain HTTP (not
HTTPS) on your LAN, add an App Transport Security exception in
`ios/Runner/Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```
(For production you'd scope this to just your local network instead of
allowing all arbitrary loads.)

**Web** — if using Ollama with a web build, start Ollama with CORS allowed
for your app's origin:
```bash
OLLAMA_ORIGINS="*" ollama serve
```

### 5. Run
```bash
flutter run                 # pick a connected device/emulator
flutter run -d chrome       # web
flutter run -d windows      # windows desktop
```

### 6. Build release binaries
```bash
flutter build apk           # Android
flutter build ios           # iOS (requires Xcode + signing)
flutter build web           # Web
flutter build windows       # Windows
flutter build macos         # macOS
flutter build linux         # Linux
```

---

## Setting up offline mode (Ollama)

1. Install Ollama on a computer: https://ollama.com/download
2. Start the server: `ollama serve` (or it may already be running as a background service).
3. In the app, go to **Settings → Offline Mode (Ollama)** and set the server
   address:
   - Same machine (desktop builds): `http://127.0.0.1:11434`
   - From a phone on the same Wi-Fi, pointing at your PC: `http://<your-pc-lan-ip>:11434`
4. Tap **Manage local models** to pull a model (e.g. `llama3`, `mistral`,
   `phi3`) directly from inside the app — this streams `ollama pull` progress
   and stores the model on the machine running the Ollama server.
5. Select **Ollama (Local / Offline)** as the active AI brain in Settings.
   You can now chat with zero internet connection (as long as the app and
   the Ollama server can reach each other).

## Setting up online providers

In **Settings → API Keys**, paste your key for whichever provider you want:
- OpenAI: https://platform.openai.com/api-keys
- Gemini: https://aistudio.google.com/apikey
- Anthropic: https://console.anthropic.com/settings/keys

Keys are written straight to the OS-level secure storage (Keychain /
Keystore / DPAPI) via `flutter_secure_storage` — never to a plain file, and
never sent anywhere except directly to that provider's API when you send a
message.

---

## Developer

**Mohan**
📧 mohanybm829@gmail.com
