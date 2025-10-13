import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    // Define the light theme data directly here
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
              } else {
                // Reconnected navigation to home route
                Navigator.of(context).pushReplacementNamed('/home');
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
                        'Sign In',
                        style: lightTheme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: lightTheme.colorScheme.primary,
                          letterSpacing: -0.5,
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
                            : 'Enter a valid email',
                        onSaved: (value) => _email = value!.trim(),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline,
                              color: lightTheme.colorScheme.primary),
                          hintText: 'Password',
                          hintStyle: TextStyle(
                              color: lightTheme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6)),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: lightTheme.colorScheme.primary,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        style:
                            TextStyle(color: lightTheme.colorScheme.onSurface),
                        obscureText: _obscure,
                        validator: (value) => (value != null && value.length >= 6)
                            ? null
                            : 'Min 6 characters',
                        onSaved: (value) => _password = value!,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/forgot-password');
                          },
                          child: Text(
                            'Forgot Password?',
                            style: lightTheme.textTheme.bodyLarge?.copyWith(
                              color: lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
                                  // Reconnected auth login logic
                                  await auth.login(_email, _password);
                                  if (!mounted) return;
                                  if (auth.token != null) {
                                    Navigator.pushReplacementNamed(
                                        context, '/home');
                                  } else if (auth.error != null) {
                                    Fluttertoast.showToast(msg: auth.error!);
                                  }
                                }
                              },
                              child: Text(
                                'Sign In',
                                style: lightTheme.textTheme.titleLarge?.copyWith(
                                  color: lightTheme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                      if (auth.error != null && !auth.isLoading)
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Text(
                            auth.error!,
                            style: TextStyle(
                              color: lightTheme.colorScheme.error,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 20),
                      Builder(builder: (context) {
                        final message = ModalRoute.of(context)
                            ?.settings
                            .arguments as String?;
                        if (message == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: lightTheme.textTheme.bodyLarge?.copyWith(
                                color: lightTheme.colorScheme.onSurface),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(
                                context, '/signup'),
                            child: Text(
                              'Sign up',
                              style: lightTheme.textTheme.bodyLarge?.copyWith(
                                color: lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: lightTheme.colorScheme.outline)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              'OR',
                              style: lightTheme.textTheme.bodyMedium?.copyWith(
                                  color: lightTheme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: lightTheme.colorScheme.outline)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          side: BorderSide(
                              color: lightTheme.colorScheme.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                          onPressed: auth.isLoading
                            ? null
                            : () async {
                                final authProvider =
                                    context.read<AuthProvider>();
                                // Reconnected Google sign-in logic
                                authProvider.clearError();
                                await authProvider.signInWithGoogle();
                                if (!mounted) return;
                                if (authProvider.token != null) {
                                  Navigator.pushReplacementNamed(
                                      context, '/home');
                                } else if (authProvider.error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(authProvider.error!)),
                                  );
                                }
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'lib/assets/google.svg',
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sign in with Google',
                              style: lightTheme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: lightTheme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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