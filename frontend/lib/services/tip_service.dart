// lib/services/tip_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_auth_app/config.dart';
import 'package:flutter_auth_app/models/tip.dart';

class TipService {
  Future<List<Tip>> fetchTips() async {
    final response = await http.get(Uri.parse('$backendUrl/api/tips'));

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      List<Tip> tips = body.map((dynamic item) => Tip.fromJson(item)).toList();
      return tips;
    } else {
      throw Exception('Failed to load tips from the server');
    }
  }
}