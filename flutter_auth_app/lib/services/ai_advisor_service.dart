import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_auth_app/config.dart';

class AiAdvisorService {
  Future<String> getAiAdvice({
    required String query,
    required String city,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/ai-advisor'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'query': query,
          'city': city,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final result = body['response'];
        if (result is String) {
          return result.isEmpty ? 'No response received' : result;
        } else {
          throw Exception('Invalid response format: expected a string');
        }
      } else {
        final Map<String, dynamic> body = json.decode(response.body);
        throw Exception(body['error'] ?? 'Failed to get AI advice');
      }
    } catch (e) {
      throw Exception('Failed to get AI advice: $e');
    }
  }
}