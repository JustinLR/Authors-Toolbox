import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'package:authors_toolbox/theme_provider.dart';
import 'package:authors_toolbox/screens/about_screen.dart';
import 'package:authors_toolbox/screens/custom_shortcuts_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage package
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final _storage = FlutterSecureStorage(); // Secure storage instance

  int _totalTokensUsed = 0;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadTokenUsage();
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

  // Load total tokens used from SharedPreferences
  Future<void> _loadTokenUsage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalTokensUsed =
          prefs.getInt('totalTokensUsed') ?? 0; // Load the token count
    });
  }

  // Calculate the cost based on token usage
  double _calculateCost() {
    double costPerThousandTokens =
        0.002; // Assuming GPT-3.5 cost here, change for other models if needed
    return (_totalTokensUsed / 1000) * costPerThousandTokens;
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
            // Add the token usage and cost details here
            Text(
              'OpenAI Usage:',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Total Tokens Used: $_totalTokensUsed',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              'Estimated Cost: \$${_calculateCost().toStringAsFixed(4)}',
              style: TextStyle(fontSize: 16),
            ),
            Divider(),
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
