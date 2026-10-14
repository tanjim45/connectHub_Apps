import 'package:connecthub/core/theme/apps_them.dart';
import 'package:connecthub/features/home_page.dart';
import 'package:flutter/material.dart';


class ConnectHubApp extends StatefulWidget {
  const ConnectHubApp({super.key});

  @override
  State<ConnectHubApp> createState() => _ConnectHubAppState();
}

class _ConnectHubAppState extends State<ConnectHubApp> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ConnectHub',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomePage(
        isDarkMode: isDarkMode,
        onThemeChanged: toggleTheme,
      ),
    );
  }
}
