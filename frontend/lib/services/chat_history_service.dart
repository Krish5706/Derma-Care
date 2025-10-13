import 'package:flutter_auth_app/models/chat_message.dart';
import 'package:flutter_auth_app/services/api_service.dart';

class ChatHistoryService {
  final ApiService _apiService = ApiService();

  /// Fetches the list of past conversations from the backend.
  ///
  /// The [token] is the user's authentication JWT.
  /// Returns a list of conversations, where each conversation is a map containing
  /// details like title, timestamp, and the messages themselves.
  Future<List<Map<String, dynamic>>> getConversations(String token) {
    return _apiService.getChatHistory(token);
  }

  Future<Map<String, dynamic>> getConversationDetails(String token, String chatId) {
    return _apiService.getChatConversation(token, chatId);
  }

  Future<void> deleteConversations(String token, List<String> conversationIds) {
    return _apiService.deleteChatHistory(token, conversationIds);
  }



  /// Saves a full conversation thread to the backend.
  ///
  /// The [messages] list contains the chat messages to be saved.
  /// The [token] is the user's authentication JWT.
  /// The optional [chatId] is used to update an existing conversation.
  Future<Map<String, dynamic>> saveConversation(
      List<ChatMessage> messages, String token,
      {String? chatId}) async {
    // A guard clause to prevent sending empty or null data to the backend.
    if (messages.isEmpty) {
      return {};
    }

    // Convert the list of ChatMessage objects into a list of Maps (JSON format)
    // that can be sent in the request body.
    final messagesJson = messages.map((msg) => msg.toJson()).toList();

    // Call the ApiService to perform the network request.
    return await _apiService.saveOrUpdateChatHistory(messagesJson, token,
        chatId: chatId);
  }
}