import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                const Icon(Icons.blur_circular, size: 72, color: AppTheme.accent),
                const SizedBox(height: 12),
                Text(AppInfo.appName,
                    style:
                        const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Version ${AppInfo.version}',
                    style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text(AppInfo.tagline,
                    style: const TextStyle(
                        color: AppTheme.accent, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Card(
            color: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(AppInfo.aboutText,
                  style: const TextStyle(height: 1.5)),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Developer',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                          fontSize: 15)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: AppTheme.textSecondary),
                      const SizedBox(width: 10),
                      Text(AppInfo.developerName,
                          style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(AppInfo.developerEmail,
                            style: const TextStyle(fontSize: 15)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy email',
                        onPressed: () {
                          Clipboard.setData(
                              const ClipboardData(text: AppInfo.developerEmail));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email copied to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Card(
            color: AppTheme.surface,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Privacy',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                          fontSize: 15)),
                  SizedBox(height: 8),
                  Text(
                    'All conversations and API keys are stored only on this '
                    'device (secure encrypted local storage). Nothing is '
                    'uploaded to any server operated by this app. When you '
                    'use an online provider (ChatGPT, Gemini, Claude), your '
                    'message is sent directly to that provider using your '
                    'own API key, subject to that provider\'s own privacy '
                    'policy.',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
