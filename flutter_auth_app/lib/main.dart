import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/profile_screen.dart';
import 'screens/home/settings_screen.dart';
import 'screens/home/history_screen.dart';
import 'screens/home/skin_tips.dart';
import 'screens/home/disease_info_screen.dart';
import 'screens/home/main_screen.dart';
import 'screens/home/skin_prediction_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'DermaCare',
            theme: ThemeData(
              brightness: Brightness.light,
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF4F8CFF),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF4F8CFF),
            ),
            themeMode: auth.themeMode,
            debugShowCheckedModeBanner: false,
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                switch (auth.status) {
                  case AuthStatus.Uninitialized:
                    return const SplashScreen();
                  case AuthStatus.Unauthenticated:
                    return const SplashScreen();
                  case AuthStatus.Authenticating:
                    return const SplashScreen();
                  case AuthStatus.Authenticated:
                    return const MainScreen();
                }
              },
            ),
            routes: {
              '/login': (_) => const LoginScreen(),
              '/signup': (_) => const SignupScreen(),
              '/forgot-password': (_) => const ForgotPasswordScreen(),
              '/home': (_) => const MainScreen(),
              '/profile': (_) => const ProfileScreen(),
              '/settings': (_) => const SettingsScreen(),
              '/history': (_) => const HistoryScreen(),
              '/skinTips': (_) => const SkinTipsPage(),
              '/skin-analysis': (_) => const SkinPredictionScreen(),
              // Pass token from AuthProvider to DiseaseInfoScreen
              '/disease-info': (context) {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                return DiseaseInfoScreen(
                  token: auth.token ?? '',
                );
              },
            },
          );
        },
      ),
    );
  }
}
