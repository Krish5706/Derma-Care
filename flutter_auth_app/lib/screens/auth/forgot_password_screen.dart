import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _newPassword = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Define the light theme data directly here to match the Sign In screen
    final lightTheme = ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: Colors.blue,
        primary: Colors.blue[700],
        surface: Colors.blue[50],
        surfaceContainerHighest: Colors.white,
      ),
      useMaterial3: true,
      textTheme: Theme.of(context).textTheme.apply(
            bodyColor: Colors.blue[900],
            displayColor: Colors.blue[900],
          ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );

    return Theme(
      data: lightTheme,
      child: Scaffold(
        backgroundColor: lightTheme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: lightTheme.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios,
                color: lightTheme.colorScheme.onSurface),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth > 600 ? 48.0 : 24.0,
                  vertical: 32.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Reset Password',
                        style: lightTheme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: lightTheme.colorScheme.primary,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Enter your email and a new password to reset your account access.',
                        style: lightTheme.textTheme.bodyLarge?.copyWith(
                          color: lightTheme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined,
                              color: lightTheme.colorScheme.primary),
                          hintText: 'Email',
                          hintStyle: TextStyle(
                              color: lightTheme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style:
                            TextStyle(color: lightTheme.colorScheme.onSurface),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => EmailValidator.validate(value ?? '')
                            ? null
                            : 'Please enter a valid email',
                        onSaved: (value) => _email = value!.trim(),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline,
                              color: lightTheme.colorScheme.primary),
                          hintText: 'New Password',
                          hintStyle: TextStyle(
                              color: lightTheme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6)),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: lightTheme.colorScheme.primary,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        style:
                            TextStyle(color: lightTheme.colorScheme.onSurface),
                        obscureText: _obscurePassword,
                        validator: (value) => (value != null && value.length >= 6)
                            ? null
                            : 'Password must be at least 6 characters',
                        onSaved: (value) => _newPassword = value!,
                        onChanged: (value) => _newPassword = value,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_person_outlined,
                              color: lightTheme.colorScheme.primary),
                          hintText: 'Confirm New Password',
                          hintStyle: TextStyle(
                              color: lightTheme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6)),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: lightTheme.colorScheme.primary,
                            ),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        style:
                            TextStyle(color: lightTheme.colorScheme.onSurface),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value != _newPassword) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      auth.isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: lightTheme.colorScheme.primary))
                          : FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: lightTheme.colorScheme.primary,
                                elevation: 2,
                              ),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  await auth.resetPassword(_email, _newPassword);
                                  if (!mounted) return;
                                  if (auth.error != null) {
                                    Fluttertoast.showToast(msg: auth.error!);
                                  } else {
                                    Fluttertoast.showToast(
                                      msg:
                                          'Password reset successfully. Please log in.',
                                      toastLength: Toast.LENGTH_LONG,
                                    );
                                    Navigator.pushReplacementNamed(context, '/login');
                                  }
                                }
                              },
                              child: Text(
                                'Reset Password',
                                style: lightTheme.textTheme.titleLarge?.copyWith(
                                  color: lightTheme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}