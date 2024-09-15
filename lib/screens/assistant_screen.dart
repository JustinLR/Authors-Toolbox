import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'package:authors_toolbox/screens/saved_chats_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  _AssistantScreenState createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // ScrollController added here
  List<Map<String, String>> _chatHistory = [];
  List<String> _savedChats = [];
  final _storage = const FlutterSecureStorage(); // Secure storage instance
  String? _apiKey; // Variable to store the OpenAI API key
  String _selectedModel = 'GPT-4o'; // Default to GPT-4
  final List<String> _models = ['GPT-4o', 'GPT-4', 'GPT-3.5']; // Model options

  bool _isResponseIncomplete =
      false; // Add this line to track incomplete responses

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

  Future<void> _saveTokenUsage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalTokensUsed', _totalTokensUsed);
  }

  Future<void> _sendQuery() async {
    String query = _queryController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _chatHistory.add({"user": query, "response": "Thinking..."});
        _isResponseIncomplete =
            false; // Reset the flag before sending a new query
      });
      _queryController.clear();

      if (_apiKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No API Key found. Please set it in Settings.')),
        );
        return;
      }

      try {
        String response = await _callOpenAIAPI(query);

        // Check if the response seems incomplete (adjust logic as needed)
        if (response.length >= 100 || response.endsWith("...")) {
          _isResponseIncomplete =
              true; // Set the flag if the response is too long or cut off
        }

        setState(() {
          _chatHistory.last["response"] = response;
        });
      } catch (e) {
        setState(() {
          _chatHistory.last["response"] = 'Error occurred: $e';
        });
      }
    }
  }

  Future<void> _continueResponse() async {
    if (_chatHistory.isEmpty) return;

    // Get the last part of the conversation to provide context
    String lastResponse = _chatHistory.last['response'] ?? '';
    String continuePrompt = 'Continue the following response: "$lastResponse"';

    try {
      String response = await _callOpenAIAPI(continuePrompt);

      // Only add the GPT response to the chat history if it's not empty
      if (response.isNotEmpty) {
        setState(() {
          _chatHistory.add({
            "user": "",
            "response": response
          }); // Only add GPT's response if it's valid
          _isResponseIncomplete =
              false; // Reset the flag after the response continues
        });
      }
    } catch (e) {
      setState(() {
        _chatHistory.add({
          "user": "",
          "response": 'Error occurred: $e'
        }); // Only add error if needed
      });
    }
  }

  int _totalTokensUsed =
      0; // Add a state variable to track the total tokens used.

  Future<String> _callOpenAIAPI(String query) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    // Construct the full conversation history to send to the API
    List<Map<String, String>> messages = [];

    // Add each previous chat history message to the request body
    for (var chat in _chatHistory) {
      messages.add({"role": "user", "content": chat["user"]!});
      messages.add({"role": "assistant", "content": chat["response"]!});
    }

    // Add the new user query at the end
    messages.add({"role": "user", "content": query});

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode({
          "model": _selectedModel == 'GPT-4' ? "gpt-4" : "gpt-3.5-turbo",
          "messages": messages, // Send the entire conversation history
          "max_tokens": 100, // Adjust as needed
        }),
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        // Get token usage details
        int tokensUsed = decodedResponse['usage']['total_tokens'];
        setState(() {
          _totalTokensUsed += tokensUsed; // Update total tokens used
        });
        setState(() {
          _totalTokensUsed += tokensUsed;
        });
        _saveTokenUsage(); // Save updated token usage
        return decodedResponse['choices'][0]['message']['content'].trim();
      } else {
        throw Exception("Failed to fetch response from OpenAI");
      }
    } catch (e) {
      throw Exception("Failed to fetch response from OpenAI: $e");
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
        const SnackBar(content: Text('Chat session saved!')),
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
      const SnackBar(content: Text('Current chat cleared!')),
    );
  }

// Add this method in your class _AssistantScreenState
  Future<void> _deleteAllChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedChats.clear(); // Clear saved chats in the state
    });
    await prefs
        .remove('savedChats'); // Remove saved chats from SharedPreferences

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All saved chats deleted!')),
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

  Widget _buildUserMessage(String message, ThemeData theme, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(child: Icon(Icons.person)), // User icon
        const SizedBox(width: 10), // Space between icon and message
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.blueGrey[700]
                  : Colors.blue[100], // Different color for user
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode
                    ? Colors.white
                    : Colors.black, // Adjust text color for dark mode
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Writing Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChatSession,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavedChatsScreen(
                    savedChats: _savedChats,
                    loadChat: _loadChatSession,
                    deleteChat: _deleteChatSession,
                    deleteAllChats: _deleteAllChats,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearChat,
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final chat = _chatHistory[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Only render user message if it's not empty
                      if (chat['user'] != null && chat['user']!.isNotEmpty)
                        _buildUserMessage(chat['user']!, theme, isDarkMode),
                      const SizedBox(height: 10),
                      // Only render GPT response if it's not empty
                      if (chat['response'] != null &&
                          chat['response']!.isNotEmpty)
                        _buildChatGPTResponse(
                            chat['response']!, theme, isDarkMode),
                      const Divider(),
                    ],
                  );
                },
              ),
            ),
          ),

          // Conditionally show the "Continue" button when the response is incomplete
          if (_isResponseIncomplete)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _continueResponse,
                child: const Text('Continue Response'),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Ask the assistant...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _sendQuery,
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatGPTResponse(
      String response, ThemeData theme, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(child: Icon(Icons.smart_toy)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
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
