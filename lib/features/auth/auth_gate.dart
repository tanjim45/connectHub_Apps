import 'package:connecthub/features/auth/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connecthub/features/home_page.dart';

class AuthGate extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const AuthGate({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Could not check login status. Please restart the app.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.data != null) {
          return HomePage(
            isDarkMode: isDarkMode,
            onThemeChanged: onThemeChanged,
          );
        }

        return const WelcomePage();
      },
    );
  }
}