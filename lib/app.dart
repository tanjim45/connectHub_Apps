
import 'package:flutter/material.dart';

import 'package:connecthub/core/theme/apps_them.dart';
import 'package:connecthub/features/home_page.dart';

class ConnectHubApp extends StatefulWidget {
  const ConnectHubApp({super.key});

  @override
  State<ConnectHubApp> createState() => _ConnectHubAppState();
}

class _ConnectHubAppState extends State<ConnectHubApp> {
  // Dark mode-এর বর্তমান অবস্থা
  bool isDarkMode = false;

  // Theme পরিবর্তন করার function
  void toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ConnectHub',

      // Light ও Dark theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Home page
      home: HomePage(
        isDarkMode: isDarkMode,
        onThemeChanged: toggleTheme,
      ),
    );
  }
}
