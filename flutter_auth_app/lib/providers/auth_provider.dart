import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../config.dart'; // Ensure this import is here
import '../services/google_auth_service.dart';

enum AuthStatus {
  Uninitialized,
  Authenticated,
  Authenticating,
  Unauthenticated
}

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _username;
  String? _email;
  String? _phone;
  bool _isLoading = false;
  String? _error;
  AuthStatus _status = AuthStatus.Uninitialized;
  ThemeMode _themeMode = ThemeMode.system;

  String? get token => _token;
  String? get username => _username;
  String? get email => _email;
  String? get phone => _phone;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AuthStatus get status => _status;
  ThemeMode get themeMode => _themeMode;

  AuthProvider() {
    _loadTheme();
    _loadToken();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode');
    if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = mode;
    await prefs.setString('themeMode', mode.name);
    notifyListeners();
  }

  // Method to refresh theme when system theme changes
  void updateSystemTheme() {
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }

  Future<void> _loadToken() async {
    _status = AuthStatus.Authenticating;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    _username = prefs.getString('username');
    _email = prefs.getString('email');
    _phone = prefs.getString('user_phone');
    if (_token != null) {
      _status = AuthStatus.Authenticated;
    } else {
      _status = AuthStatus.Unauthenticated;
    }
    notifyListeners();
  }

  // *** MODIFIED CODE STARTS HERE ***
  // Dynamically set backend URL for different platforms
  static String get _baseUrl {
    // Always use the URL from the central config file.
    return backendUrl;
  }
  // *** MODIFIED CODE ENDS HERE ***

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== LOGIN DEBUG ===');
      print('Email: $email');
      print('Backend URL: $_baseUrl/login');

      final uri = Uri.parse('$_baseUrl/login');
      print('Parsed URI: $uri');

      final requestBody = jsonEncode({'email': email, 'password': password});
      print('Request body: $requestBody');

      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 10));

      print('Response status: ${res.statusCode}');
      print('Response headers: ${res.headers}');
      print('Response body: ${res.body}');

      if (res.statusCode == 200) {
        try {
          final data = jsonDecode(res.body);
          print('Parsed response data: $data');

          _token = data['token'];
          _username = data['username'];
          _email = data['email'];

          if (_token == null || _username == null || _email == null) {
            _error = 'Invalid response format from server';
            _status = AuthStatus.Unauthenticated;
            print('Error: Missing required fields in response');
            return;
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', _token!);
          await prefs.setString('username', _username!);
          await prefs.setString('email', _email!);

          print(
              'Login successful! User: $_username, Token: ${_token!.substring(0, 20)}...');
          _error = null;
          _status = AuthStatus.Authenticated;
        } catch (parseError) {
          _error = 'Failed to parse server response';
          _status = AuthStatus.Unauthenticated;
          print('JSON parse error: $parseError');
        }
      } else {
        try {
          final data = jsonDecode(res.body);
          _error =
              data['message'] ?? 'Login failed with status ${res.statusCode}';
        } catch (parseError) {
          _error = 'Login failed with status ${res.statusCode}';
        }
        _status = AuthStatus.Unauthenticated;
        print('Login failed: $_error');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _error = 'Connection timeout. Please check your network.';
      } else if (e.toString().contains('SocketException')) {
        _error = 'Network error. Please check if the server is running.';
      } else {
        _error = 'Network error: ${e.toString()}';
      }
      _status = AuthStatus.Unauthenticated;
      print('Login exception: $e');
    }

    _isLoading = false;
    notifyListeners();
    print('=== LOGIN DEBUG END ===');
  }

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== REGISTRATION DEBUG ===');
      print('Username: $username');
      print('Email: $email');
      print('Backend URL: $_baseUrl/register');

      final uri = Uri.parse('$_baseUrl/register');
      print('Parsed URI: $uri');

      final requestBody = jsonEncode(
          {'username': username, 'email': email, 'password': password});
      print('Request body: $requestBody');

      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 10));

      print('Response status: ${res.statusCode}');
      print('Response headers: ${res.headers}');
      print('Response body: ${res.body}');

      if (res.statusCode == 201) {
        print('Registration successful! Auto-logging in...');
        _error = null;
        // Auto-login after successful registration
        await login(email, password);
      } else {
        try {
          final data = jsonDecode(res.body);
          _error = data['message'] ??
              'Registration failed with status ${res.statusCode}';
        } catch (parseError) {
          _error = 'Registration failed with status ${res.statusCode}';
        }
        print('Registration failed: $_error');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _error = 'Connection timeout. Please check your network.';
      } else if (e.toString().contains('SocketException')) {
        _error = 'Network error. Please check if the server is running.';
      } else {
        _error = 'Network error: ${e.toString()}';
      }
      print('Registration exception: $e');
    }

    _isLoading = false;
    notifyListeners();
    print('=== REGISTRATION DEBUG END ===');
  }

  Future<void> resetPassword(String email, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/auth/reset-password');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'new_password': newPassword}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _error = null;
      } else {
        try {
          final data = jsonDecode(response.body);
          _error = data['message'] ??
              'Request failed with status ${response.statusCode}';
        } catch (_) {
          _error = 'Request failed with status ${response.statusCode}';
        }
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _error = 'Connection timeout. Please check your network and server.';
      } else if (e.toString().contains('SocketException')) {
        _error = 'Network error. Please check if the server is running.';
      } else {
        _error = 'An unexpected error occurred: ${e.toString()}';
      }
      print('Reset Password exception: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    // Sign out from Google if signed in
    try {
      await GoogleAuthService.signOut();
    } catch (e) {
      print('Error signing out from Google: $e');
    }
    // Set status to Uninitialized so the app shows the splash/root screen
    // after logout instead of directly going to the login page.
    _status = AuthStatus.Uninitialized;
    final prefs = await SharedPreferences.getInstance();
    // Only remove auth-related keys, not all prefs
    await prefs.remove('jwt_token');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('user_phone');
    await prefs.remove('profile_picture');
    notifyListeners();
  }

  Future<void> updateUsername(String newUsername) async {
    _username = newUsername;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newUsername);
    notifyListeners();
  }

  Future<void> updatePhone(String newPhone) async {
    _phone = newPhone;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_phone', newPhone);
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Google Sign-In implementation
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== GOOGLE SIGN-IN PROVIDER DEBUG ===');

      final result = await GoogleAuthService.signInWithGoogle();

      if (result != null) {
        _token = result['token'];
        _username = result['username'];
        _email = result['email'];

        if (_token == null || _username == null || _email == null) {
          _error = 'Invalid response from Google authentication';
          print('Error: Missing required fields in Google auth response');
          return;
        }

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
        await prefs.setString('username', _username!);
        await prefs.setString('email', _email!);

        // Save profile picture if available
        if (result['profile_picture'] != null) {
          await prefs.setString('profile_picture', result['profile_picture']);
        }

        print('Google sign-in successful! User: $_username');
        _error = null;
        _status = AuthStatus.Authenticated;
      } else {
        _error = 'Google sign-in was cancelled';
        print('Google sign-in was cancelled by user');
      }
    } catch (e) {
      _error = 'Google Sign-In failed: ${e.toString()}';
      print('Google sign-in exception: $e');
    }

    _isLoading = false;
    notifyListeners();
    print('=== GOOGLE SIGN-IN PROVIDER DEBUG END ===');
  }
}
