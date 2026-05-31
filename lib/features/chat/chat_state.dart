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

  Future<void> sendMessage(String rawContent) async {
    final content = rawContent.trim();
    if (content.isEmpty || _sending) return;

    _sending = true;
    _error = null;
    _messages = [..._messages, Message.local(role: 'user', content: content)];
    notifyListeners();

    try {
      _currentChat ??= await _createChatAndTrack();
      final result = await _service.sendMessage(_currentChat!.id, content);
      _messages = [..._messages]
        ..removeLast() // drop optimistic user bubble
        ..add(result.userMessage)
        ..add(result.assistantMessage);
      await _refreshChatsQuietly();
    } on DioException catch (e) {
      _error = _messageFrom(e);
      _messages = [..._messages]..removeLast(); // roll back optimistic bubble
    }

    _sending = false;
    notifyListeners();
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

  Future<Chat> _createChatAndTrack() async {
    final chat = await _service.createChat();
    _chats = [chat, ..._chats];
    return chat;
  }

  /// After an upload that may have created a chat, point at it.
  void _adoptChat(String chatId) {
    if (_currentChat?.id == chatId) return;
    _currentChat = _chats.firstWhere(
      (c) => c.id == chatId,
      orElse: () => Chat(id: chatId),
    );
  }

  Future<void> _refreshChatsQuietly() async {
    try {
      _chats = await _service.listChats();
    } on DioException catch (_) {
      // keep existing list; not worth surfacing
    }
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Cannot reach the server. Is the backend running?';
    }
    return 'Request failed (${e.response?.statusCode ?? 'network'}).';
  }
}
