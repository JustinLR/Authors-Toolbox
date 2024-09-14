import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'package:authors_toolbox/screens/saved_chats_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AssistantScreen extends StatefulWidget {
  @override
  _AssistantScreenState createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // ScrollController added here
  List<Map<String, String>> _chatHistory = [];
  List<String> _savedChats = [];
  final _storage = FlutterSecureStorage(); // Secure storage instance
  String? _apiKey; // Variable to store the OpenAI API key
  String _selectedModel = 'GPT-4o'; // Default to GPT-4
  List<String> _models = ['GPT-4o', 'GPT-4', 'GPT-3.5']; // Model options

  @override
  void initState() {
    super.initState();
    _loadSavedChats(); // Load saved chat sessions on app start
    _loadApiKey(); // Load API key from secure storage
  }

  // Load the OpenAI API key from secure storage
  Future<void> _loadApiKey() async {
    String? apiKey = await _storage.read(key: 'openai_api_key');
    if (apiKey != null) {
      setState(() {
        _apiKey = apiKey; // Set the API key in state
      });
    }
  }

  // Function to send query to OpenAI API using the stored API key
  Future<void> _sendQuery() async {
    String query = _queryController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _chatHistory.add({"user": query, "response": "Thinking..."});
      });
      _queryController.clear();

      // Ensure API key is loaded before making the call
      if (_apiKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No API Key found. Please set it in Settings.')),
        );
        return;
      }

      try {
        // Make the actual API call to OpenAI using the retrieved API key
        String response = await _callOpenAIAPI(query);
        setState(() {
          _chatHistory.last["response"] =
              response; // Update with actual response
        });
      } catch (e) {
        setState(() {
          _chatHistory.last["response"] = 'Error occurred: $e'; // Show error
        });
      }
    }
  }

  // Call OpenAI API with selected model
  Future<String> _callOpenAIAPI(String query) async {
    final url = Uri.parse(
        "https://api.openai.com/v1/chat/completions"); // OpenAI endpoint

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey", // Use the API key
        },
        body: jsonEncode({
          "model": _selectedModel == 'GPT-4'
              ? "gpt-4"
              : "gpt-3.5-turbo", // Use selected model
          "messages": [
            {
              "role": "user",
              "content": query
            } // Send the query as a user message
          ],
          "max_tokens": 100, // Limit the response length
        }),
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return decodedResponse['choices'][0]['message']['content']
            .trim(); // Extract the response text from GPT-4
      } else {
        // Log the error response details for debugging
        print("Failed request: ${response.statusCode}");
        print("Response body: ${response.body}");
        throw Exception("Failed to fetch response from OpenAI");
      }
    } catch (e) {
      print("Error occurred: $e");
      throw Exception("Failed to fetch response from OpenAI");
    }
  }

  // Save the current chat session
  Future<void> _saveChatSession() async {
    if (_chatHistory.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String savedChat = jsonEncode(_chatHistory);
      _savedChats.add(savedChat);

      // Save updated chats
      await prefs.setStringList('savedChats', _savedChats);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat session saved!')),
      );
    }
  }

  // Load saved chat sessions from SharedPreferences
  Future<void> _loadSavedChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedChats = prefs.getStringList('savedChats') ?? [];
    });
  }

  // Clear current chat
  void _clearChat() {
    setState(() {
      _chatHistory.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Current chat cleared!')),
    );
  }

  // Load a saved chat session
  void _loadChatSession(String savedChat) {
    List<dynamic> decodedChat = jsonDecode(savedChat);
    setState(() {
      _chatHistory =
          decodedChat.map((chat) => Map<String, String>.from(chat)).toList();
    });
  }

  // Delete a saved chat session
  Future<void> _deleteChatSession(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedChats.removeAt(index);
    });
    await prefs.setStringList('savedChats', _savedChats);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Writing Assistant'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveChatSession, // Save the current chat session
          ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              // Navigate to saved chats screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedChatsScreen(
                    savedChats: _savedChats,
                    loadChat: _loadChatSession,
                    deleteChat: _deleteChatSession,
                    deleteAllChats:
                        _deleteAllChats, // Function to delete all chats
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: _clearChat, // Clear the current chat
          ),
        ],
      ),
      drawer: AppNavigationDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.end, // Align content to the left
        children: [
          // Dropdown for Model Selection anchored at the top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _selectedModel,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedModel = newValue!;
                });
              },
              items: _models.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Scrollbar(
              // Add Scrollbar
              controller: _scrollController, // Use the same controller
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController, // Attach ScrollController
                padding: EdgeInsets.all(16),
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final chat = _chatHistory[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserMessage(chat['user']!, theme, isDarkMode),
                      SizedBox(height: 10),
                      _buildChatGPTResponse(
                          chat['response']!, theme, isDarkMode),
                      Divider(),
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    minLines: 1, // Minimum height (1 line)
                    maxLines: 5, // Maximum height (5 lines)
                    decoration: InputDecoration(
                      hintText: 'Ask the assistant...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _sendQuery,
                  child: Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // New function to delete all saved chats
  Future<void> _deleteAllChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedChats.clear();
    });
    await prefs
        .remove('savedChats'); // Remove all saved chats from SharedPreferences

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All saved chats deleted!')),
    );
  }

  Widget _buildUserMessage(String message, ThemeData theme, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(child: Icon(Icons.person)),
        SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blueGrey[700] : Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatGPTResponse(
      String response, ThemeData theme, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(child: Icon(Icons.smart_toy)),
        SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.green[700] : Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              response,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
