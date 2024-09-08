import 'package:flutter/material.dart';
import 'package:authors_toolbox/screens/home_page.dart';
import 'package:authors_toolbox/screens/book_hub_screen.dart';
import 'package:authors_toolbox/screens/progress_tracker_screen.dart';
import 'package:authors_toolbox/screens/thesaurus_screen.dart';
import 'package:authors_toolbox/screens/assistant_screen.dart';
import 'package:authors_toolbox/screens/settings_screen.dart';

class AppNavigationDrawer extends StatelessWidget {
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
            title: Text('Thesaurus'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ThesaurusScreen()),
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
            title: Text('Settings'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
