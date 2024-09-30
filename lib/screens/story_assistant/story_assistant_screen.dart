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
  bool _clearOutput = false; // Checkbox state for clearing output
  String? _lastGptResponse; // To store the last GPT response for editing

  final _storage = const FlutterSecureStorage(); // Secure storage instance

  @override
  void initState() {
    super.initState();
    _loadDataFromStorage();
  }

  @override
  void dispose() {
    _saveDataToStorage();
    super.dispose();
  }

  // Save data to storage
  void _saveDataToStorage() async {
    await _storage.write(key: 'characters', value: jsonEncode(_characters));
    await _storage.write(key: 'locations', value: jsonEncode(_locations));
    await _storage.write(key: 'chatHistory', value: jsonEncode(_chatHistory));
  }

  // Load data from storage
  void _loadDataFromStorage() async {
    String? charactersJson = await _storage.read(key: 'characters');
    String? locationsJson = await _storage.read(key: 'locations');
    String? chatHistoryJson = await _storage.read(key: 'chatHistory');

    setState(() {
      if (charactersJson != null) {
        _characters = (jsonDecode(charactersJson) as List)
            .map((e) => Character.fromJson(e))
            .toList();
      }
      if (locationsJson != null) {
        _locations = (jsonDecode(locationsJson) as List)
            .map((e) => Location.fromJson(e))
            .toList();
      }
      if (chatHistoryJson != null) {
        _chatHistory = List<String>.from(jsonDecode(chatHistoryJson));
      }
    });
  }

  bool _isEditRequest(String userInput) {
    final lowerInput = userInput.toLowerCase();
    return lowerInput.contains("edit") ||
        lowerInput.contains("change") ||
        lowerInput.contains("not quite") ||
        lowerInput.contains("can we fix") ||
        lowerInput.contains("that's not right") ||
        lowerInput.contains("adjust") ||
        lowerInput.contains("modify") ||
        lowerInput.contains("improve") ||
        lowerInput.contains("not what i meant") ||
        lowerInput.contains("tweak") ||
        lowerInput.contains("can you redo") ||
        lowerInput.contains("previous") ||
        lowerInput.contains("last") ||
        lowerInput.contains("request");
  }

  // Fetch the API key from secure storage
  Future<String?> _getApiKey() async {
    return await _storage.read(key: 'openai_api_key');
  }

// Make a real request to the OpenAI API
  Future<String> _sendToGpt(String input, {bool isEdit = false}) async {
    String? apiKey = await _getApiKey();
    if (apiKey == null) {
      return jsonEncode({'type': 'error', 'message': 'API key not found.'});
    }

    final messages = [
      {
        'role': 'system',
        'content':
            'You are a helpful assistant. Always place conversational replies before "---" and character/location descriptions after "---". Also provide character descriptions in a format useful for character sheets, adding new sections if necessary. Structure each response like this: **Name**, **Appearance**, **Personality**, **Skills**, **Backstory**, and any other sections you find relevant.'
      },
      {'role': 'user', 'content': input}
    ];

    // If it's an edit request, include the previous GPT response in the conversation
    if (isEdit && _lastGptResponse != null) {
      messages.insert(1, {'role': 'assistant', 'content': _lastGptResponse!});
    }

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': messages,
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
    bool isEditRequest = _isEditRequest(userInput);

    // If it's an edit request, send the previous GPT response along with the new user input
    String gptResponse = await _sendToGpt(userInput, isEdit: isEditRequest);
    Map<String, dynamic> parsedResponse = jsonDecode(gptResponse);

    print('Parsed response: $parsedResponse');

    if (parsedResponse.containsKey('choices') &&
        parsedResponse['choices'].isNotEmpty) {
      String content = parsedResponse['choices'][0]['message']['content'];
      setState(() {
        // Add user input to the chat history, but only for new requests, not edits
        if (!isEditRequest) {
          _chatHistory.add('User: $userInput');
        } else {
          // For edits, we show that the user wanted to modify something
          _chatHistory.add('User: (Edit Request) $userInput');
        }

        // Clear input field
        _chatController.clear();

        // Parse the response to split conversation and story-building content
        _parseGptResponse(content);

        // Save the last GPT response for future edits
        _lastGptResponse = content;
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

  // Clear the chat history and optionally clear the output
  void _clearChatAndOutput() {
    setState(() {
      _chatHistory.clear();
      if (_clearOutput) {
        _gptOutput = ''; // Clear the output box if the checkbox is checked
      }
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
                              onPressed: _clearChatAndOutput,
                              child: const Text('Clear Chat'),
                            ),
                            const SizedBox(width: 10),
                            Checkbox(
                              value: _clearOutput,
                              onChanged: (bool? value) {
                                setState(() {
                                  _clearOutput = value ?? false;
                                });
                              },
                            ),
                            const Text('Clear Output Box')
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
