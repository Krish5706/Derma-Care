import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class AdvisorHistoryService {
  final String _baseUrl = '$backendUrl/advisor-history';

  /// Saves a single AI Skin Advisor entry to the backend.
  Future<void> saveAdvisorEntry({
    required String query,
    required String city,
    required String response,
    required String token,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'query': query,
          'city': city,
          'response': response,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (res.statusCode != 201) {
        throw Exception('Failed to save advisor history: ${res.body}');
      }
    } catch (e) {
      // Rethrow to be handled by the UI
      throw Exception('Failed to save advisor history: ${e.toString()}');
    }
  }

  /// Fetches all AI Skin Advisor history entries for the authenticated user.
  Future<List<Map<String, dynamic>>> fetchAdvisorHistory({
    required String token,
  }) async {
    try {
      final res = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load advisor history: ${res.body}');
      }
    } catch (e) {
      throw Exception('Failed to load advisor history: ${e.toString()}');
    }
  }

  /// Deletes selected AI Skin Advisor history entries.
  Future<void> deleteAdvisorEntries({
    required List<String> ids,
    required String token,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'ids': ids}),
      );

      if (res.statusCode != 200) {
        throw Exception('Failed to delete entries: ${res.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete entries: ${e.toString()}');
    }
  }
}