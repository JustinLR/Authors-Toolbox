import 'package:flutter/material.dart';
import 'package:authors_toolbox/screens/home_page.dart';
import 'package:authors_toolbox/screens/book_hub_screen.dart';
import 'package:authors_toolbox/screens/progress_tracker_screen.dart';
import 'package:authors_toolbox/screens/thesaurus_screen.dart';
import 'package:authors_toolbox/screens/story_assistant_screen.dart';
import 'package:authors_toolbox/screens/settings_screen.dart';
import 'package:authors_toolbox/screens/profile_screen.dart'; // Add your profile screen
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:path/path.dart' as path; // For handling file paths

class AppNavigationDrawer extends StatefulWidget {
  const AppNavigationDrawer({super.key});

  @override
  _AppNavigationDrawerState createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  List<String> customShortcuts = [];
  bool _isHoveringSettings = false;
  bool _isHoveringProfile = false;

  @override
  void initState() {
    super.initState();
    _loadCustomShortcuts();
  }

  // Load custom shortcuts from SharedPreferences
  Future<void> _loadCustomShortcuts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      customShortcuts = prefs.getStringList('customShortcuts') ?? [];
    });
  }

  // Helper method to format shortcut names
  String _formatShortcutName(String shortcut) {
    if (shortcut.startsWith('http')) {
      // If it's a URL, extract the domain
      Uri uri = Uri.parse(shortcut);
      return uri.host; // Returns something like 'chatgpt.com'
    } else {
      // If it's a file path, extract the file name
      return path.basename(shortcut); // Returns something like 'document.pdf'
    }
  }

  // Function to open the shortcut (file or URL)
  Future<void> _openShortcut(String shortcut) async {
    if (shortcut.startsWith('http')) {
      // If it's a URL, use url_launcher to open it
      if (await canLaunchUrl(Uri.parse(shortcut))) {
        await launchUrl(Uri.parse(shortcut));
      } else {
        throw 'Could not launch $shortcut';
      }
    } else {
      // If it's a file path, open it using the default file opener
      if (File(shortcut).existsSync()) {
        if (Platform.isWindows) {
          await Process.run('explorer', [shortcut]);
        } else if (Platform.isMacOS) {
          await Process.run('open', [shortcut]);
        } else if (Platform.isLinux) {
          await Process.run('xdg-open', [shortcut]);
        }
      } else {
        throw 'File does not exist: $shortcut';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Navigation list at the top
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.blueGrey,
                  ),
                  child: Row(
                    children: [
                      // App Logo on the left
                      Image.asset(
                        'assets/logo.png', // Path to your app logo
                        width: 48, // Adjust the size of the logo
                        height: 48,
                      ),
                      const SizedBox(width: 10), // Space between logo and text
                      // App Name on the right
                      const Text(
                        'Authors Toolbox',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24, // Font size for the app name
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Thesaurus'),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ThesaurusScreen()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Book Hub'),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BookHubScreen()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Story Builder'),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const StoryAssistantScreen()),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Progress Tracker'),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProgressTrackerScreen()),
                    );
                  },
                ),
                const Divider(),
                // Dynamically display custom shortcuts with formatted names
                ...customShortcuts.map((shortcut) {
                  return ListTile(
                    title: Text(_formatShortcutName(shortcut)),
                    onTap: () {
                      _openShortcut(shortcut); // Handle file/URL opening
                    },
                  );
                }).toList(),
              ],
            ),
          ),
          // Settings and Profile icons aligned at the bottom
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Align icons to left and right
              children: [
                // Settings icon on the bottom left
                MouseRegion(
                  cursor: SystemMouseCursors
                      .click, // Change the cursor to a hand when hovering
                  onEnter: (_) {
                    setState(() {
                      _isHoveringSettings = true; // Change hover state to true
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _isHoveringSettings =
                          false; // Change hover state to false
                    });
                  },
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()),
                      );
                    },
                    child: Icon(
                      Icons.settings,
                      size: 32,
                      color: _isHoveringSettings
                          ? Colors.blue // Hover effect color
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white // White in dark mode
                              : Colors.grey), // Grey in light mode
                    ),
                  ),
                ),
                // Profile icon on the bottom right
                MouseRegion(
                  cursor: SystemMouseCursors
                      .click, // Change the cursor to a hand when hovering
                  onEnter: (_) {
                    setState(() {
                      _isHoveringProfile = true; // Change hover state to true
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _isHoveringProfile = false; // Change hover state to false
                    });
                  },
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ProfileScreen()), // Navigate to the profile screen
                      );
                    },
                    child: CircleAvatar(
                      radius: 20, // Size of the profile icon
                      backgroundColor: _isHoveringProfile
                          ? Colors.blue
                              .withOpacity(0.8) // Change background on hover
                          : Colors.blueGrey, // Default background color
                      child: Icon(
                        Icons
                            .person, // You can replace this with an actual image
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey, // Icon color changes with theme
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
