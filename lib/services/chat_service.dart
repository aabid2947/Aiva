import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/chat.dart';
import '../models/message.dart';
import 'api_client.dart';

class SendMessageResult {
  const SendMessageResult({
    required this.userMessage,
    required this.assistantMessage,
  });

  final Message userMessage;
  final Message assistantMessage;
}

/// Talks to the backend /chats endpoints (token attached by ApiClient).
class ChatService {
  ChatService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;
  Dio get _dio => _api.dio;

  Future<List<Chat>> listChats() async {
    final res = await _dio.get<List<dynamic>>('/chats');
    return (res.data ?? [])
        .map((e) => Chat.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Chat> createChat({String? title}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/chats',
      data: {'title': title},
    );
    return Chat.fromJson(res.data!);
  }

  Future<List<Message>> getMessages(String chatId) async {
    final res = await _dio.get<List<dynamic>>('/chats/$chatId/messages');
    return (res.data ?? [])
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SendMessageResult> sendMessage(String chatId, String content) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/chats/$chatId/messages',
      data: {'content': content},
    );
    return _resultFrom(res.data!);
  }

  /// Uploads a file for summarization. If [chatId] is null the backend creates a chat.
  Future<SendMessageResult> uploadFile({
    required String? chatId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final fields = <String, dynamic>{
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    };
    if (chatId != null) fields['chat_id'] = chatId;
    final res = await _dio.post<Map<String, dynamic>>(
      '/summarize/upload',
      data: FormData.fromMap(fields),
    );
    return _resultFrom(res.data!);
  }

  SendMessageResult _resultFrom(Map<String, dynamic> data) => SendMessageResult(
        userMessage: Message.fromJson(data['user_message'] as Map<String, dynamic>),
        assistantMessage:
            Message.fromJson(data['assistant_message'] as Map<String, dynamic>),
      );
}
