import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'dart:convert';

// Import forms and widgets
import 'package:authors_toolbox/forms/character_form.dart';
import 'package:authors_toolbox/forms/location_form.dart';

// Import the models
import 'package:authors_toolbox/models/character.dart';
import 'package:authors_toolbox/models/location.dart';

class StoryBuilderScreen extends StatefulWidget {
  const StoryBuilderScreen({super.key});

  @override
  _StoryBuilderScreenState createState() => _StoryBuilderScreenState();
}

class _StoryBuilderScreenState extends State<StoryBuilderScreen> {
  // GPT Input Controller
  TextEditingController _gptController = TextEditingController();
  bool _isLoading = false;

  // State variables to manage the form visibility
  bool _showCharacterForm = false;
  bool _showLocationForm = false;

  Character? _generatedCharacter;
  Location? _generatedLocation;

  // Simulate GPT request (mocked for now)
  Future<String> _sendToGpt(String input, String type) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate delay
    if (type == 'character') {
      return jsonEncode({
        'type': 'character',
        'name': 'Arden',
        'age': 30,
        'role': 'Warrior',
        'backstory': 'A brave warrior with a tragic past.'
      });
    } else if (type == 'location') {
      return jsonEncode({
        'type': 'location',
        'name': 'The Mystic Forest',
        'description': 'A dense forest full of ancient secrets.',
      });
    } else {
      return jsonEncode({'type': 'unknown', 'message': 'Invalid request.'});
    }
  }

  // Handle GPT input and display appropriate form
  Future<void> _handleGptInput(String type) async {
    setState(() {
      _isLoading = true;
    });

    String userInput = _gptController.text;
    String gptResponse = await _sendToGpt(userInput, type);
    Map<String, dynamic> parsedResponse = jsonDecode(gptResponse);

    if (parsedResponse['type'] == 'character') {
      setState(() {
        _generatedCharacter = Character(
          name: parsedResponse['name'],
          age: parsedResponse['age'],
          role: parsedResponse['role'],
        );
        _showCharacterForm = true;
        _showLocationForm = false;
      });
    } else if (parsedResponse['type'] == 'location') {
      setState(() {
        _generatedLocation = Location(
          name: parsedResponse['name'],
          description: parsedResponse['description'],
        );
        _showLocationForm = true;
        _showCharacterForm = false;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Conditionally show either the back button or the navigation drawer button
        leading: (_showCharacterForm || _showLocationForm)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Go back to the initial input screen
                  setState(() {
                    _showCharacterForm = false;
                    _showLocationForm = false;
                  });
                },
              )
            : Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context)
                          .openDrawer(); // Open navigation drawer
                    },
                  );
                },
              ),
        title: const Text('Story Builder'),
      ),
      drawer: const AppNavigationDrawer(),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _showCharacterForm
                ? CharacterForm(
                    onSave: (Character character) {
                      // Handle character save logic here
                    },
                    editingCharacter: _generatedCharacter,
                  )
                : _showLocationForm
                    ? LocationForm(
                        onSave: (Location location) {
                          // Handle location save logic here
                        },
                        editingLocation: _generatedLocation,
                      )
                    : _buildInitialView(), // Initial view for text input and buttons
      ),
    );
  }

  // The initial view with a text box and buttons
  Widget _buildInitialView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'What would you like help with?',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _gptController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Describe what you need help with...',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  _handleGptInput('character');
                },
                child: const Text('Character'),
              ),
              ElevatedButton(
                onPressed: () {
                  _handleGptInput('location');
                },
                child: const Text('Location'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Handle "Other" option logic here if needed
                },
                child: const Text('Other'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
