
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class ApiService {
  static String get _baseUrl => backendUrl;

  static Future<Map<String, dynamic>> analyzeSkin(File image) async {
    final uri = Uri.parse('$_baseUrl/predict');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', image.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      return json.decode(responseBody);
    } else {
      throw Exception('Failed to analyze skin condition.');
    }
  }

  static Future<void> saveScanResult(
      String userId, Map<String, dynamic> result) async {
    final uri = Uri.parse('$_baseUrl/history');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'prediction': result['prediction'],
        'confidence': result['confidence'],
        'image_url': result['image_url'], // Assuming the backend returns this
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to save scan result.');
    }
  }

  static Future<List<dynamic>> getScanHistory(String userId) async {
    final uri = Uri.parse('$_baseUrl/history/$userId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get scan history.');
    }
  }

  Future<void> saveChatHistory(List<Map<String, dynamic>> messages, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'messages': messages}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to save chat history');
    }
  }

  Future<Map<String, dynamic>> saveOrUpdateChatHistory(
      List<Map<String, dynamic>> messages, String token,
      {String? chatId}) async {
    final body = {
      'messages': messages,
      if (chatId != null) 'chat_id': chatId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to save or update chat history');
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistory(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/history'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load chat history');
    }
  }

  Future<Map<String, dynamic>> getChatConversation(String token, String chatId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/history/$chatId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load conversation details');
    }
  }

  Future<void> deleteChatHistory(String token, List<String> chatIds) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/history/delete'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'ids': chatIds}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete chat history');
    }
  }
}
