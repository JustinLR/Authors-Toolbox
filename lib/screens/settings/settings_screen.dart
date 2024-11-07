import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'package:authors_toolbox/theme/theme_provider.dart';
import 'package:authors_toolbox/screens/about/about_screen.dart';
import 'package:authors_toolbox/screens/custom/custom_shortcuts_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage package
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final _storage = const FlutterSecureStorage(); // Secure storage instance

  int _totalTokensUsed = 0;
  double _costPerThousandTokens = 0.002; // Update based on your model's cost

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
    return (_totalTokensUsed / 1000) * _costPerThousandTokens;
  }

  // Save token usage to SharedPreferences
  Future<void> _saveTokenUsage(int tokens) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _totalTokensUsed += tokens;
    await prefs.setInt('totalTokensUsed', _totalTokensUsed);
  }

  // Function to add token usage, should be called from the chat processing code
  void addTokenUsage(int tokensUsed) {
    setState(() {
      _saveTokenUsage(tokensUsed);
    });
  }

  // Save the OpenAI API key to secure storage
  Future<void> _saveApiKey() async {
    await _storage.write(key: 'openai_api_key', value: _apiKeyController.text);
    setState(() {
      _apiKeyController.clear(); // Clear the input field after saving the key
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API Key saved successfully!')),
    );
  }

  // Clear the API key from secure storage
  Future<void> _clearApiKey() async {
    await _storage.delete(key: 'openai_api_key');
    setState(() {
      _apiKeyController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key cleared successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      drawer: const AppNavigationDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Selector
            const Text(
              'Select Theme:',
              style: TextStyle(fontSize: 20),
            ),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: themeProvider.isDarkMode,
              onChanged: (bool value) {
                themeProvider.toggleTheme(value);
              },
            ),
            const SizedBox(height: 20),
            const Divider(),
            // OpenAI API Key Section
            const Text(
              'OpenAI API Key:',
              style: TextStyle(fontSize: 20),
            ),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'Enter OpenAI API Key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            // Buttons to save and clear the API key
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveApiKey,
                  child: const Text('Save API Key'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _clearApiKey,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Clear API Key'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            // Token usage and cost details section
            const Text(
              'OpenAI Usage:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              'Total Tokens Used: $_totalTokensUsed',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              'Estimated Cost: \$${_calculateCost().toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(),
            ListTile(
              title: const Text('Manage Custom Shortcuts'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomShortcutsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('About'),
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
