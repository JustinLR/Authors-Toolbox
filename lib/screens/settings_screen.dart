import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'package:authors_toolbox/theme_provider.dart';
import 'package:authors_toolbox/screens/about_screen.dart';
import 'package:authors_toolbox/screens/custom_shortcuts_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage package

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final _storage = FlutterSecureStorage(); // Secure storage instance

  @override
  void initState() {
    super.initState();
    _loadApiKey(); // Load API key from secure storage when the screen is initialized
  }

  // Load the OpenAI API key from secure storage
  Future<void> _loadApiKey() async {
    String? apiKey = await _storage.read(key: 'openai_api_key');
    if (apiKey != null) {
      setState(() {
        _apiKeyController.text =
            apiKey; // Populate the input field if a key is found
      });
    }
  }

// Save the OpenAI API key to secure storage
  Future<void> _saveApiKey() async {
    await _storage.write(key: 'openai_api_key', value: _apiKeyController.text);
    setState(() {
      _apiKeyController.clear(); // Clear the input field after saving the key
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('API Key saved successfully!')),
    );
  }

  // Clear the API key from secure storage
  Future<void> _clearApiKey() async {
    await _storage.delete(key: 'openai_api_key');
    setState(() {
      _apiKeyController.clear();
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('API Key cleared successfully!')));
  }

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
            // Theme Selector
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
            // OpenAI API Key Section
            Text(
              'OpenAI API Key:',
              style: TextStyle(fontSize: 20),
            ),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'Enter OpenAI API Key',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            // Buttons to save and clear the API key
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveApiKey,
                  child: Text('Save API Key'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _clearApiKey,
                  child: Text('Clear API Key'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
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
            // About section
            ListTile(
              title: Text('About'),
              onTap: () {
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
