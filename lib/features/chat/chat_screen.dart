import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/message.dart';
import '../auth/auth_state.dart';
import '../mail/mail_screen.dart';
import 'chat_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    context.read<ChatState>().sendMessage(text);
  }

  Future<void> _attach() async {
    final result = await FilePicker.pickFiles(withData: true);
    if (!mounted || result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't read that file.")),
      );
      return;
    }
    context.read<ChatState>().attachAndSummarize(bytes, picked.name);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(chat.currentChat?.displayTitle ?? 'AIVA'),
      ),
      drawer: const _HistoryDrawer(),
      body: Column(
        children: [
          if (chat.error != null)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(8),
              child: Text(
                chat.error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          Expanded(child: _MessageList(chat: chat)),
          _Composer(
            controller: _controller,
            onSend: _send,
            onAttach: _attach,
            busy: chat.busy,
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.chat});

  final ChatState chat;

  @override
  Widget build(BuildContext context) {
    if (chat.loadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chat.messages.isEmpty && !chat.busy) {
      return const _EmptyState();
    }

    // Newest at the bottom: reverse:true renders index 0 at the bottom.
    final items = <Widget>[
      for (final m in chat.messages) _Bubble(message: m),
      if (chat.busy) const _TypingBubble(),
    ].reversed.toList();

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'Ask AIVA to summarize a file, set a reminder, '
              'or watch your email for important mail.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 24,
          height: 16,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.busy,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Attach a file to summarize',
              onPressed: busy ? null : onAttach,
              icon: const Icon(Icons.attach_file),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Message AIVA…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: busy ? null : onSend,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryDrawer extends StatelessWidget {
  const _HistoryDrawer();

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatState>();
    final auth = context.watch<AuthState>();
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: const Text('AIVA', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(auth.user?.email ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New chat'),
              onTap: () {
                context.read<ChatState>().startNewChat();
                Navigator.of(context).pop();
              },
            ),
            const Divider(),
            Expanded(
              child: chat.loadingChats
                  ? const Center(child: CircularProgressIndicator())
                  : chat.chats.isEmpty
                      ? const Center(child: Text('No chats yet'))
                      : ListView.builder(
                          itemCount: chat.chats.length,
                          itemBuilder: (_, i) {
                            final c = chat.chats[i];
                            final selected = c.id == chat.currentChat?.id;
                            return ListTile(
                              selected: selected,
                              leading: const Icon(Icons.chat_bubble_outline),
                              title: Text(
                                c.displayTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                context.read<ChatState>().openChat(c);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.mark_email_unread_outlined),
              title: const Text('Mail monitoring'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const MailScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () => context.read<AuthState>().logout(),
            ),
          ],
        ),
      ),
    );
  }
}
