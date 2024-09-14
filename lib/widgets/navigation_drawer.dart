import 'package:flutter/material.dart';
import 'package:authors_toolbox/screens/home_page.dart';
import 'package:authors_toolbox/screens/book_hub_screen.dart';
import 'package:authors_toolbox/screens/progress_tracker_screen.dart';
import 'package:authors_toolbox/screens/thesaurus_screen.dart';
import 'package:authors_toolbox/screens/story_builder_screen.dart';
import 'package:authors_toolbox/screens/settings_screen.dart';
import 'package:authors_toolbox/screens/assistant_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:path/path.dart' as path; // For handling file paths

class AppNavigationDrawer extends StatefulWidget {
  @override
  _AppNavigationDrawerState createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  List<String> customShortcuts = [];

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
      if (await canLaunch(shortcut)) {
        await launch(shortcut);
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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
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
                SizedBox(width: 10), // Space between logo and text
                // App Name on the right
                Text(
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
            title: Text('Home'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
          ListTile(
            title: Text('Book Hub'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => BookHubScreen()),
              );
            },
          ),
          ListTile(
            title: Text('Progress Tracker'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => ProgressTrackerScreen()),
              );
            },
          ),
          ListTile(
            title: Text('Assistant'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AssistantScreen()),
              );
            },
          ),
          ListTile(
            title: Text('Thesaurus'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ThesaurusScreen()),
              );
            },
          ),
          ListTile(
            title: Text('Story Builder'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => StoryBuilderScreen()),
              );
            },
          ),
          ListTile(
            title: Text('Settings'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
          Divider(),
          // Dynamically display custom shortcuts with formatted names
          ...customShortcuts.map((shortcut) {
            return ListTile(
              title: Text(
                  _formatShortcutName(shortcut)), // Display the formatted name
              onTap: () {
                _openShortcut(shortcut); // Handle file/URL opening
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}
