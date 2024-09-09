import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'package:authors_toolbox/theme_provider.dart';
import 'package:authors_toolbox/screens/about_screen.dart';
import 'package:authors_toolbox/screens/custom_shortcuts_screen.dart'; // Import the CustomShortcutsScreen

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      drawer: AppNavigationDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Theme:',
              style: TextStyle(fontSize: 20),
            ),
            SwitchListTile(
              title: Text('Dark Mode'),
              value: themeProvider.isDarkMode,
              onChanged: (bool value) {
                themeProvider.toggleTheme(value);
              },
            ),
            SizedBox(height: 20),
            Divider(),
            // Button to navigate to the custom shortcuts management screen
            ListTile(
              title: Text('Manage Custom Shortcuts'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomShortcutsScreen(),
                  ),
                );
              },
            ),
            Divider(),
            ListTile(
              title: Text('About'),
              onTap: () {
                // Navigate to the AboutScreen when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
