import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart'; // Import window_manager
import 'package:provider/provider.dart';
import 'package:authors_toolbox/screens/home_page.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure that Flutter binding is initialized

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Set the window title for Windows
  WindowOptions windowOptions = WindowOptions(
    title: 'Authors Toolbox', // Set the desired window title here
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Authors Toolbox', // Flutter app title
      theme: ThemeData.light(), // Default theme
      darkTheme: ThemeData.dark(), // Dark theme
      themeMode: themeProvider.isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light, // Toggle based on isDarkMode
      home: HomePage(), // Change this to the home screen
    );
  }
}
