import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart'; // <-- IMPORT ADDED HERE

class GoogleAuthService {
  // Use a named constructor for initialization based on platform.
  // We make it a static final instance to ensure it's created only once.
  static final GoogleSignIn _googleSignIn = kIsWeb
      ? GoogleSignIn(
          clientId: googleWebClientId,
          scopes: const ['email', 'profile'],
        )
      : GoogleSignIn(
          // No clientId needed for Android/iOS, configured in google-services.json
          scopes: const ['email', 'profile'],
          // Request an ID token by specifying your OAuth 2.0 Client ID for backend
          serverClientId: googleWebClientId,
        );

  static String get _baseUrl {
    return backendUrl;
  }

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('=== GOOGLE SIGN-IN SERVICE DEBUG ===');

      // The new API uses `_googleSignIn.signIn()`
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google sign-in was cancelled by user');
        return null;
      }

      print('Google user signed in: ${googleUser.email}');
      print('Display name: ${googleUser.displayName}');
      print('Photo URL: ${googleUser.photoUrl}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('Got Google auth tokens');
      // The `accessToken` getter has been removed, but `idToken` is what
      // you need for backend authentication.
      print('ID token available: ${googleAuth.idToken != null}');

      // Send the ID token to your backend for verification
      final response = await _sendTokenToBackend(googleAuth.idToken);
      if (response != null) {
        print('Backend authentication successful');
        return response;
      } else {
        print('Backend authentication failed');
        return null;
      }
    } catch (error) {
      print('Google sign-in error: $error');

      if (error.toString().contains('sign_in_failed')) {
        throw Exception(
            'Google Sign-In configuration error. Please check your setup.');
      } else if (error.toString().contains('network_error')) {
        throw Exception(
            'Network error. Please check your internet connection.');
      } else {
        throw Exception('Google sign-in failed: $error');
      }
    }
  }

  static Future<Map<String, dynamic>?> _sendTokenToBackend(
      String? idToken) async {
    if (idToken == null) {
      print('ID token is null');
      return null;
    }

    try {
      print('Sending ID token to backend...');

      final uri = Uri.parse('$_baseUrl/auth/google');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'idToken': idToken,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('Backend response status: ${response.statusCode}');
      print('Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'token': data['token'],
          'username': (data['user'] ?? {})['username'] ?? '',
          'email': (data['user'] ?? {})['email'] ?? '',
          'profile_picture': (data['user'] ?? {})['profile_picture'],
        };
      } else {
        print('Backend returned error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error sending token to backend: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      // The new API uses `_googleSignIn.signOut()`
      await _googleSignIn.signOut();
      print('Google sign-out successful');
    } catch (error) {
      print('Google sign-out error: $error');
    }
  }

  static Future<bool> isSignedIn() async {
    // The new API uses `_googleSignIn.isSignedIn()`
    return await _googleSignIn.isSignedIn();
  }

  static GoogleSignInAccount? getCurrentUser() {
    // The new API uses `_googleSignIn.currentUser`
    return _googleSignIn.currentUser;
  }
}