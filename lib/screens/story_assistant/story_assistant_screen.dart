import 'dart:convert';
import 'dart:io';
import 'package:authors_toolbox/models/story_assistant/model.dart';
import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:authors_toolbox/widgets/loading_dots.dart';

class StoryAssistantScreen extends StatefulWidget {
  const StoryAssistantScreen({super.key});

  @override
  _StoryAssistantScreenState createState() => _StoryAssistantScreenState();
}

class _StoryAssistantScreenState extends State<StoryAssistantScreen>
    with WidgetsBindingObserver {
  TextEditingController _chatController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  List<String> _chatHistory = [];
  Model? _model;
  String? _lastUserInput; // Store the last user input for reloading

  final _storage = const FlutterSecureStorage();
  Map<String, List<String>> _savedChats = {};
  String? _currentChatId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChatData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveDataToStorage();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveDataToStorage(); // Save data when the app goes to the background
    }
  }

  // Initialize chat data from storage
  void _initializeChatData() async {
    await _loadSavedChats();
    await _loadCurrentChatId();
    await _loadCharacterCardFromStorage();
    // If no chat is currently loaded, create "Chat 1"
    if (_currentChatId == null || _currentChatId!.isEmpty) {
      _startNewChat(); // Automatically create a new chat if none exists
    }
  }

  void _saveDataToStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_currentChatId != null) {
      _savedChats[_currentChatId!] = _chatHistory;
    }
    await prefs.setString('savedChats', jsonEncode(_savedChats));
    await prefs.setString('currentChatId', _currentChatId ?? '');
    if (_model != null) {
      await prefs.setString('characterCard', jsonEncode(_model!.toJson()));
    }
  }

  Future<void> _loadSavedChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedChatsJson = prefs.getString('savedChats');
    if (savedChatsJson != null) {
      setState(() {
        _savedChats = Map<String, List<String>>.from(
          jsonDecode(savedChatsJson).map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ),
        );
      });
    }
  }

  Future<void> _loadCurrentChatId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? chatId = prefs.getString('currentChatId');
    if (chatId != null && chatId.isNotEmpty) {
      setState(() {
        _currentChatId = chatId;
        _chatHistory = _savedChats[chatId] ?? [];
      });
      _scrollToBottom();
    }
  }

  Future<void> _loadCharacterCardFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? characterCardJson = prefs.getString('characterCard');
    if (characterCardJson != null) {
      setState(() {
        _model = Model.fromJson(jsonDecode(characterCardJson));
      });
    }
  }

  Future<void> _loadCharacterCard() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      try {
        final file = File(filePath);
        String jsonContent = await file.readAsString();
        Map<String, dynamic> characterCard = jsonDecode(jsonContent);

        setState(() {
          _model = Model.fromJson(characterCard);
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('characterCard', jsonContent);
      } catch (e) {
        print('Error loading character card: $e');
      }
    }
  }

  Future<String?> _getApiKey() async {
    String? apiKey = await _storage.read(key: 'openai_api_key');
    if (apiKey == null) {
      print('API key not found in secure storage');
    }
    return apiKey;
  }

  Future<void> _sendToGptStream(String input) async {
    String? apiKey = await _getApiKey();
    if (apiKey == null) {
      setState(() {
        _chatHistory.add('Error: API key not found.');
      });
      return;
    }

    if (_model == null) {
      setState(() {
        _chatHistory.add('Error: Model not found in character card.');
      });
      return;
    }

    // Construct the system prompt using the character card information
    String systemPrompt = 'You are a helpful assistant named ${_model!.name}. '
        'You are open to discussing a wide range of topics, including potentially sensitive or NSFW content, dont worry about keeping things tame, in a professional and respectful manner. '
        'Your traits are: ${_model!.personalityTraits.join(", ")}. '
        'Your preferences are: ${_model!.preferences.entries.map((e) => "${e.key}: ${e.value}").join(", ")}. '
        'Parameters for responses are: ${_model!.parameters.entries.map((e) => "${e.key}: ${e.value}").join(", ")}. '
        'Focus on following these traits, preferences, and parameters while providing your responses.';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': input}
    ];

    final request = http.Request(
      'POST',
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
    );

    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    });

    request.body = jsonEncode({
      'model': _model!.model,
      'messages': messages,
      'max_tokens': _model!.parameters['max_tokens'] ?? 500,
      'temperature': _model!.parameters['temperature'] ?? 0.7,
      'stream': true // Enable streaming response
    });

    final streamedResponse = await request.send();

    final stream = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    StringBuffer currentResponse = StringBuffer();
    setState(() {
      _chatHistory.add('Assistant: ');
    });

    await for (var line in stream) {
      if (line.isNotEmpty && line.startsWith("data: ")) {
        final jsonString = line
            .substring(6)
            .trim(); // Remove "data: " prefix and trim whitespace
        try {
          if (jsonString.isNotEmpty && jsonString != "[DONE]") {
            final chunk = jsonDecode(jsonString);

            if (chunk.containsKey('choices')) {
              setState(() {
                currentResponse
                    .write(chunk['choices'][0]['delta']['content'] ?? "");
                _chatHistory[_chatHistory.length - 1] =
                    'Assistant: ${currentResponse.toString()}';
              });
              _scrollToBottom();
            }
          }
        } catch (e) {
          print('Error parsing chunk: $e');
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleGptInput() async {
    // Check if there's no active chat, create one if needed
    if (_currentChatId == null || _currentChatId!.isEmpty) {
      _startNewChat();
    }

    if (_chatController.text.trim().isEmpty) {
      print("No input provided");
      return;
    }

    final userInput = _chatController.text;
    _chatController.clear();
    _lastUserInput = userInput; // Store the last user input for reloading

    setState(() {
      _isLoading = true;
      _chatHistory.add('User: $userInput');
    });

    try {
      await _sendToGptStream(userInput);
      _saveDataToStorage();
    } catch (e) {
      print('Exception occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadResponse() async {
    if (_lastUserInput == null || _lastUserInput!.isEmpty) {
      print("No previous input to reload.");
      return;
    }

    setState(() {
      _isLoading = true;
      _chatHistory.removeLast(); // Remove the previous AI response
    });

    try {
      await _sendToGptStream(_lastUserInput!);
      _saveDataToStorage();
    } catch (e) {
      print('Exception occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _clearChatAndOutput() {
    setState(() {
      _chatHistory.clear();
    });
    _saveDataToStorage();
  }

  void _startNewChat() {
    setState(() {
      _currentChatId = 'Chat ${_savedChats.length + 1}';
      _chatHistory = [];
      _savedChats[_currentChatId!] = _chatHistory;
    });
    _saveDataToStorage();
  }

  void _switchChat(String chatId) {
    setState(() {
      _currentChatId = chatId;
      _chatHistory = List<String>.from(_savedChats[chatId]!);
    });
    _scrollToBottom();
    _saveDataToStorage();
  }

  void _deleteChat(String chatId) {
    setState(() {
      _savedChats.remove(chatId);
      if (_currentChatId == chatId) {
        _currentChatId = null;
        _chatHistory.clear();
      }
    });
    _saveDataToStorage();
  }

  void _showContextMenu(Offset position) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx, position.dy),
      items: [
        const PopupMenuItem<String>(
          value: 'reload',
          child: Text('Reload'),
        ),
        const PopupMenuItem<String>(
          value: 'clear',
          child: Text('Clear Chat'),
        ),
      ],
    );

    if (result == 'clear') {
      _clearChatAndOutput();
    } else if (result == 'reload') {
      _reloadResponse();
    }
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
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Text(_model != null
            ? 'Using Model: ${_model!.model}'
            : 'No model loaded.'),
      ),
      drawer: const AppNavigationDrawer(),
      body: Row(
        children: [
          // Sidebar for old chats
// Updated Column for the saved chats section without the Clear Chat button
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                // New Chat Button
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: _startNewChat,
                    icon: const Icon(Icons.add),
                    label: const Text('New Chat'),
                  ),
                ),
                // List of saved chats
                Expanded(
                  child: ListView(
                    children: _savedChats.keys.map((chatId) {
                      return ListTile(
                        title: Text(chatId),
                        onTap: () => _switchChat(chatId),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteChat(chatId),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Spacer pushes the button to the bottom
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: _loadCharacterCard,
                    child: const Text('Load Character Card'),
                  ),
                ),
              ],
            ),
          ),
          // Main chat area
          Expanded(
            child: Column(children: [
              Expanded(
                child: GestureDetector(
                  onSecondaryTapDown: (details) {
                    _showContextMenu(details.globalPosition);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _chatHistory.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SelectableText(_chatHistory[index]),
                                Divider(
                                    height: 1,
                                    color: Colors.grey.withOpacity(0.3)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Assistant'),
                      const SizedBox(width: 8),
                      const LoadingDots(), // Use the LoadingDots animation here
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    // TextField configuration
                    TextField(
                      controller: _chatController,
                      maxLines: 5, // Limit the expansion to 5 lines
                      minLines: 1, // Start with 1 line
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Chat with Assistant...',
                        contentPadding: EdgeInsets.fromLTRB(12, 12, 48,
                            12), // Padding to keep text within bounds
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) => _handleGptInput(),
                    ),
                    // Positioned Send button anchored to the bottom-right
                    Positioned(
                      right: 4, // Position it within the TextField border
                      bottom: 4, // Anchor it to the bottom
                      child: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _handleGptInput,
                        splashRadius: 24.0, // Static size for the button
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
