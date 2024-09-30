import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart'; // Import window_manager
import 'package:provider/provider.dart';
import 'package:authors_toolbox/screens/home_page/home_page.dart';
import 'package:authors_toolbox/screens/book/book_hub_screen.dart';
import 'package:authors_toolbox/screens/progress_tracker/progress_tracker_screen.dart';
import 'package:authors_toolbox/screens/thesaurus/thesaurus_screen.dart';
import 'package:authors_toolbox/screens/story_assistant/story_assistant_screen.dart';
import 'package:authors_toolbox/screens/settings/settings_screen.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure that Flutter binding is initialized

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Set the window title for Windows
  WindowOptions windowOptions = const WindowOptions(
    title: 'Authors Toolbox', // Set the desired window title here
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Authors Toolbox',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/', // Initial route points to HomePage
      routes: {
        '/': (context) => const HomePage(), // HomePage route
        '/book_hub': (context) => const BookHubScreen(), // Book Hub route
        '/progress_tracker': (context) =>
            const ProgressTrackerScreen(), // Progress Tracker route
        '/thesaurus': (context) => ThesaurusScreen(), // Thesaurus route
        '/story_builder': (context) =>
            const StoryAssistantScreen(), // Story Builder route
        '/settings': (context) => const SettingsScreen(), // Settings route
      },
    );
  }
}
