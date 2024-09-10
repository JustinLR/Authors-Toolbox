import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class CustomShortcutsScreen extends StatefulWidget {
  @override
  _CustomShortcutsScreenState createState() => _CustomShortcutsScreenState();
}

class _CustomShortcutsScreenState extends State<CustomShortcutsScreen> {
  List<String> customShortcuts = []; // List to store custom shortcuts
  final TextEditingController _shortcutController =
      TextEditingController(); // Controller for shortcut input

  @override
  void initState() {
    super.initState();
    _loadCustomShortcuts(); // Load saved shortcuts on init
  }

  // Load custom shortcuts from SharedPreferences
  Future<void> _loadCustomShortcuts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      customShortcuts = prefs.getStringList('customShortcuts') ?? [];
    });
  }

  // Save custom shortcuts to SharedPreferences
  Future<void> _saveCustomShortcuts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('customShortcuts', customShortcuts);
  }

  // Add a new shortcut
  void _addShortcut(String shortcut) {
    if (shortcut.isNotEmpty) {
      setState(() {
        customShortcuts.add(shortcut);
        _shortcutController.clear(); // Clear the input field after adding
      });
      _saveCustomShortcuts(); // Save the updated shortcuts
    }
  }

  // Remove a shortcut
  void _removeShortcut(int index) {
    setState(() {
      customShortcuts.removeAt(index);
    });
    _saveCustomShortcuts(); // Save changes after removing a shortcut
  }

  // Open a file or URL
  Future<void> _openShortcut(String shortcut) async {
    if (shortcut.startsWith('http')) {
      // If it's a URL, use url_launcher to open it
      if (await canLaunch(shortcut)) {
        await launch(shortcut);
      } else {
        throw 'Could not launch $shortcut';
      }
    } else {
      // Otherwise, assume it's a file path and open it
      if (File(shortcut).existsSync()) {
        // If it's on Windows
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Shortcuts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _shortcutController,
              decoration: InputDecoration(
                labelText: 'Enter new shortcut (URL or File Path)',
                hintText: 'Shortcut URL or file path',
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _addShortcut(_shortcutController.text);
              },
              child: Text('Add Shortcut'),
            ),
            SizedBox(height: 20),
            Divider(),
            Text(
              'Manage Shortcuts:',
              style: TextStyle(fontSize: 20),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: customShortcuts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(customShortcuts[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _removeShortcut(index);
                      },
                    ),
                    onTap: () {
                      _openShortcut(customShortcuts[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
