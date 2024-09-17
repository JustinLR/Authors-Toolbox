import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import the models
import 'package:authors_toolbox/models/character.dart';
import 'package:authors_toolbox/models/location.dart';

class StoryAssistantScreen extends StatefulWidget {
  const StoryAssistantScreen({super.key});

  @override
  _StoryAssistantScreenState createState() => _StoryAssistantScreenState();
}

class _StoryAssistantScreenState extends State<StoryAssistantScreen> {
  // GPT Input Controllers
  TextEditingController _chatController = TextEditingController();
  bool _isLoading = false;

  String _gptOutput = '';
  List<Character> _characters = [];
  List<Location> _locations = [];
  List<String> _chatHistory = [];

  final _storage = const FlutterSecureStorage(); // Secure storage instance

  // Fetch the API key from secure storage
  Future<String?> _getApiKey() async {
    return await _storage.read(key: 'openai_api_key');
  }

  // Make a real request to the OpenAI API
  Future<String> _sendToGpt(String input) async {
    String? apiKey = await _getApiKey();
    if (apiKey == null) {
      return jsonEncode({'type': 'error', 'message': 'API key not found.'});
    }

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful assistant. Always place conversational replies before "---" and character/location descriptions after "---". Also provide character descriptions in a format useful for character sheets, adding new sections if necessary. Structure each response like this: **Name**, **Appearance**, **Personality**, **Skills**, **Backstory**, and any other sections you find relevant.'
          },
          {'role': 'user', 'content': input}
        ],
        'max_tokens': 500,
        'n': 1,
        'stop': null,
        'temperature': 0.7,
      }),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return response.body;
    } else {
      return jsonEncode(
          {'type': 'error', 'message': 'Failed to fetch data from GPT.'});
    }
  }

  Future<void> _handleGptInput() async {
    setState(() {
      _isLoading = true;
    });

    String userInput = _chatController.text;
    String gptResponse = await _sendToGpt(userInput);
    Map<String, dynamic> parsedResponse = jsonDecode(gptResponse);

    print('Parsed response: $parsedResponse');

    if (parsedResponse.containsKey('choices') &&
        parsedResponse['choices'].isNotEmpty) {
      String content = parsedResponse['choices'][0]['message']['content'];
      setState(() {
        // Add user input to the chat history
        _chatHistory.add('User: $userInput');

        // Clear input field
        _chatController.clear();

        // Parse the response to split conversation and story-building content
        _parseGptResponse(content);
      });
    } else {
      print('Error: ${parsedResponse['message']}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _parseGptResponse(String content) {
    // Split the response into conversation and details based on '---'
    final sections = content.split('---');

    // Chat part before the '---'
    final chatContent = sections[0].trim();

    // Content after the '---' for character or location description
    final characterDetails = sections.length > 1 ? sections[1].trim() : '';

    setState(() {
      // Add only the conversational part to the chat history
      if (chatContent.isNotEmpty) {
        _chatHistory.add('GPT: $chatContent');
      }

      // Display the description part only in the output box
      _gptOutput = characterDetails.isNotEmpty ? characterDetails : '';
    });
  }

  // Save the GPT output to the selected collapsable field
  void _saveOutput(String field) {
    if (field == 'Character') {
      _characters.add(
          Character(name: 'Generated Character', age: 0, role: _gptOutput));
    } else if (field == 'Location') {
      _locations
          .add(Location(name: 'Generated Location', description: _gptOutput));
    }
    setState(() {});
  }

  // Clear the chat history
  void _clearChat() {
    setState(() {
      _chatHistory.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Open navigation drawer
              },
            );
          },
        ),
        title: const Text('Story Assistant'),
      ),
      drawer: const AppNavigationDrawer(),
      body: Row(
        children: [
          // GPT Output Box and Save Button
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : SingleChildScrollView(
                                child: Text(_gptOutput),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Save to'),
                            content: DropdownButton<String>(
                              items: <String>['Character', 'Location']
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  _saveOutput(newValue);
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
          // Chat Box and Collapsable Fields
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Chat Box
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListView.builder(
                                itemCount: _chatHistory.length,
                                itemBuilder: (context, index) {
                                  return Text(_chatHistory[index]);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _chatController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Chat with GPT...',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _handleGptInput,
                              child: const Text('Send'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _clearChat,
                              child: const Text('Clear Chat'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Collapsable Fields
                  Expanded(
                    flex: 2,
                    child: ListView(
                      children: [
                        // Characters Section with slight outline
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ExpansionTile(
                            title: const Text('Characters'),
                            children: _characters
                                .map((character) => ListTile(
                                      title: Text(character.name),
                                      subtitle: Text('Role: ${character.role}'),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Locations Section with slight outline
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ExpansionTile(
                            title: const Text('Locations'),
                            children: _locations
                                .map((location) => ListTile(
                                      title: Text(location.name),
                                      subtitle: Text(location.description),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
