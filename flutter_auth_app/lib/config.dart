import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Automatically select backend URL for each platform
String get backendUrl {
  if (kIsWeb) {
    // Use localhost for web development
    return 'http://localhost:5000';
  } else if (Platform.isAndroid) {
    // Use 10.0.2.2 for Android emulator, or your PC's IP for physical device
    return 'http://10.244.25.224:5000';
  } else {
    // Default for other platforms (iOS, etc.)
    return 'http://127.0.0.1:5000';
  }
}

// IMPORTANT: Do not hardcode API keys in your source code.
// Use environment variables or a secure secret management solution.
// For production, remove the defaultValue and rely solely on --dart-define.
const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AIzaSyBwuWcgn7JwPMWR158XIlnKtZlvbcaBzlU');

// Google OAuth client ID used for Web and as server client ID for mobile
const String googleWebClientId =
    '742123302553-88e0099nok872g2re7e5l9m0v0h2ldh0.apps.googleusercontent.com';
