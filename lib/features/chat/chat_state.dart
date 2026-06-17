import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/chat.dart';
import '../../models/message.dart';
import '../../services/chat_service.dart';

/// Holds the chat list, the open chat, and its messages.
class ChatState extends ChangeNotifier {
  ChatState({ChatService? service}) : _service = service ?? ChatService();

  final ChatService _service;

  List<Chat> _chats = [];
  Chat? _currentChat;
  List<Message> _messages = [];
  bool _loadingChats = false;
  bool _loadingMessages = false;
  bool _sending = false;
  bool _uploading = false;
  String? _error;

  List<Chat> get chats => _chats;
  Chat? get currentChat => _currentChat;
  List<Message> get messages => _messages;
  bool get loadingChats => _loadingChats;
  bool get loadingMessages => _loadingMessages;
  bool get sending => _sending;
  bool get uploading => _uploading;
  bool get busy => _sending || _uploading;
  String? get error => _error;

  Future<void> loadChats() async {
    _loadingChats = true;
    notifyListeners();
    try {
      _chats = await _service.listChats();
    } on DioException catch (e) {
      _error = _messageFrom(e);
    }
    _loadingChats = false;
    notifyListeners();
  }

  void startNewChat() {
    _currentChat = null;
    _messages = [];
    _error = null;
    notifyListeners();
  }

  /// Open a chat by id when only the id is known (e.g. tapping a 'summary_ready'
  /// notification). Uses the loaded list entry if present (for its title); refreshes
  /// once if missing, then falls back to a minimal chat so messages still load.
  Future<void> openChatById(String chatId) async {
    Chat? chat = _findChat(chatId);
    if (chat == null) {
      await _refreshChatsQuietly();
      chat = _findChat(chatId);
    }
    await openChat(chat ?? Chat(id: chatId));
  }

  Chat? _findChat(String id) {
    for (final c in _chats) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> openChat(Chat chat) async {
    _currentChat = chat;
    _messages = [];
    _loadingMessages = true;
    _error = null;
    notifyListeners();
    try {
      _messages = await _service.getMessages(chat.id);
    } on DioException catch (e) {
      _error = _messageFrom(e);
    }
    _loadingMessages = false;
    notifyListeners();
  }

  /// Sends a message and returns AIVA's reply text (or null on error/empty),
  /// so a voice-initiated send can speak the response.
  Future<String?> sendMessage(String rawContent) async {
    final content = rawContent.trim();
    if (content.isEmpty || _sending) return null;

    _sending = true;
    _error = null;
    _messages = [..._messages, Message.local(role: 'user', content: content)];
    notifyListeners();

    String? reply;
    try {
      _currentChat ??= await _createChatAndTrack();
      final result = await _service.sendMessage(_currentChat!.id, content);
      _messages = [..._messages]
        ..removeLast() // drop optimistic user bubble
        ..add(result.userMessage)
        ..add(result.assistantMessage);
      reply = result.assistantMessage.content;
      await _refreshChatsQuietly();
      _syncCurrentChat(); // pick up the server-assigned title (P12)
    } on DioException catch (e) {
      _error = _messageFrom(e);
      _messages = [..._messages]..removeLast(); // roll back optimistic bubble
    }

    _sending = false;
    notifyListeners();
    return reply;
  }

  Future<void> attachAndSummarize(Uint8List bytes, String filename) async {
    if (busy) return;

    _uploading = true;
    _error = null;
    _messages = [..._messages, Message.local(role: 'user', content: '\u{1F4CE} $filename')];
    notifyListeners();

    try {
      final result =
          await _service.uploadFile(chatId: _currentChat?.id, bytes: bytes, filename: filename);
      _messages = [..._messages]
        ..removeLast() // drop optimistic attachment bubble
        ..add(result.userMessage)
        ..add(result.assistantMessage);
      await _refreshChatsQuietly();
      _adoptChat(result.assistantMessage.chatId);
    } on DioException catch (e) {
      _error = _messageFrom(e);
      _messages = [..._messages]..removeLast();
    }

    _uploading = false;
    notifyListeners();
  }

  /// Show an AIVA confirmation bubble after Gmail is connected (via the OAuth
  /// deep link). Local/ephemeral — the real handler already greets on next reply.
  void announceGmailConnected() {
    _messages = [
      ..._messages,
      Message.local(
        role: 'assistant',
        content: 'Gmail connected ✅\n'
            "You'll now get a notification whenever an important email arrives.",
      ),
    ];
    notifyListeners();
  }

  Future<Chat> _createChatAndTrack() async {
    final chat = await _service.createChat();
    _chats = [chat, ..._chats];
    return chat;
  }

  /// After an upload that may have created a chat, point at it (the refreshed
  /// list entry carries the server-assigned title).
  void _adoptChat(String chatId) {
    _currentChat = _chats.firstWhere(
      (c) => c.id == chatId,
      orElse: () => _currentChat ?? Chat(id: chatId),
    );
  }

  /// Re-point the open chat to its refreshed list entry so its title (auto-set
  /// by the backend from the first message) shows in the app bar. (P12)
  void _syncCurrentChat() {
    final id = _currentChat?.id;
    if (id == null) return;
    for (final c in _chats) {
      if (c.id == id) {
        _currentChat = c;
        return;
      }
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> _refreshChatsQuietly() async {
    try {
      _chats = await _service.listChats();
    } on DioException catch (_) {
      // keep existing list; not worth surfacing
    }
  }

  String _messageFrom(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Cannot reach the server. Check your connection and try again.';
    }
    final status = e.response?.statusCode;
    if (status == 413) {
      // Either nginx (HTML body) or the API (JSON detail) rejected an oversized
      // upload — give a clear message instead of the generic fallback.
      return 'That file is too large to summarize. Please upload a file under 50 MB.';
    }
    if (status != null && status >= 500) {
      return 'Something went wrong on our end. Please try again in a moment.';
    }
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    return 'Something went wrong. Please try again.';
  }
}
