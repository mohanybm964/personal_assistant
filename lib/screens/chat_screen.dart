import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/ai_provider_config.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatProvider>();
      if (chat.currentConversation == null) {
        chat.startNewConversation();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final settings = context.watch<SettingsProvider>();
    _scrollToBottom();

    return Scaffold(
      drawer: _buildDrawer(context, chat),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.blur_circular, color: AppTheme.accent),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(AppInfo.appName, style: TextStyle(fontSize: 16)),
                Text(
                  settings.settings.activeProvider.label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New chat',
            onPressed: () => chat.startNewConversation(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) =>
                        ChatBubble(message: chat.messages[index]),
                  ),
          ),
          MessageInput(
            isSending: chat.isSending,
            onSend: (text) => chat.sendMessage(text, settings),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.blur_circular, size: 72, color: AppTheme.accent),
            const SizedBox(height: 16),
            const Text(
              'At your service.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything — I can work online with ChatGPT, Gemini or '
              'Claude using your API key, or fully offline with a local '
              'Ollama model.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.9)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, ChatProvider chat) {
    final conversations = chat.allConversations;
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.blur_circular, color: AppTheme.accent, size: 28),
                  SizedBox(width: 10),
                  Text('Conversations',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: conversations.isEmpty
                  ? const Center(
                      child: Text('No conversations yet',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    )
                  : ListView.builder(
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final c = conversations[index];
                        final isActive = chat.currentConversation?.id == c.id;
                        return ListTile(
                          selected: isActive,
                          selectedTileColor: AppTheme.accent.withOpacity(0.08),
                          leading: const Icon(Icons.chat_bubble_outline,
                              color: AppTheme.accent),
                          title: Text(c.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => chat.deleteConversation(c),
                          ),
                          onTap: () {
                            chat.openConversation(c);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
            const Divider(color: AppTheme.textSecondary, height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.accent),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
