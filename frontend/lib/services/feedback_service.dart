import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class FeedbackService {
  static String get _baseUrl => backendUrl;

  static Future<Map<String, dynamic>> submitFeedback(String message, String token) async {
    final uri = Uri.parse('$_baseUrl/feedback');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'message': message}),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to submit feedback: ${response.body}');
    }
  }
}
