import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';

class PredictionHistoryService {
  static String get _baseUrl => backendUrl;

  // Save a prediction with image to history (multipart + auth)
  static Future<void> savePrediction({
    required File image,
    required String prediction,
    required double confidence,
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/history');
      final req = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('image', image.path))
        ..fields['prediction'] = prediction
        ..fields['confidence'] = confidence.toString();

      final res = await req.send();
      if (res.statusCode != 201) {
        final body = await res.stream.bytesToString();
        throw Exception('Failed to save history (${res.statusCode}): $body');
      }
    } catch (e) {
      if (e is SocketException || e is http.ClientException) {
        throw Exception('Network error. Please check your connection.');
      }
      throw Exception('Failed to save history: ${e.toString()}');
    }
  }

  // Fetch authenticated user's history
  static Future<List<Map<String, dynamic>>> fetchHistory({
    required String token,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/history');
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode != 200) {
        throw Exception('Failed to load history: ${res.statusCode}');
      }

      final List<dynamic> data = json.decode(res.body);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      if (e is SocketException || e is http.ClientException) {
        throw Exception('Network error. Please check your connection.');
      }
      throw Exception('Failed to load history: ${e.toString()}');
    }
  }

  // Clear all history for the authenticated user
  static Future<void> clearHistory({required String token}) async {
    try {
      final url = Uri.parse('$_baseUrl/history/clear');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to clear history');
      }
    } catch (e) {
      if (e is SocketException || e is http.ClientException) {
        throw Exception('Network error. Please check your connection.');
      }
      throw Exception(
          'Failed to clear history: ${e.toString().replaceAll('Exception:', '').trim()}');
    }
  }

  // Delete a specific history item by ID
  static Future<void> deleteHistoryItem({
    required String token,
    required String itemId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/history/$itemId');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete history item');
      }
    } catch (e) {
      if (e is SocketException || e is http.ClientException) {
        throw Exception('Network error. Please check your connection.');
      }
      throw Exception(
          'Failed to delete history item: ${e.toString().replaceAll('Exception:', '').trim()}');
    }
  }
}