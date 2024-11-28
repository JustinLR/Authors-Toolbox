import 'dart:async';
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
import 'package:flutter/services.dart';

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
  Completer<void>? _cancelCompleter;

  List<String> _chatHistory = [];
  Model? _model;
  String? _lastUserInput;
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
    if (state == AppLifecycleState.resumed) {
      // Resume animations or timers if needed
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveDataToStorage();
      // Optionally cancel ongoing animations here
    }
  }

  ////////////////////////
  // Initialize Chat Data
  ////////////////////////

  Future<void> _initializeChatData() async {
    await _loadSavedChats();
    await _loadCurrentChatId();
    await _loadCharacterCardFromStorage();
    if (_currentChatId == null || _currentChatId!.isEmpty) {
      _startNewChat();
    }
  }
  /////////////////////////////
  // Load Saved Chats from Storage
  /////////////////////////////

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

  ////////////////////////
  // Save Data to Storage
  ////////////////////////

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

  ////////////////////////////
  // Load Current Chat ID
  ////////////////////////////

  Future<void> _loadCurrentChatId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? chatId = prefs.getString('currentChatId');
    if (chatId != null && chatId.isNotEmpty) {
      setState(() {
        _currentChatId = chatId;
        _chatHistory = _savedChats[chatId] ?? [];
      });
      _saveDataToStorage();
      _scrollToBottom();
    }
  }

  ////////////////////////////////////////
  // Load Character Card from Storage
  ////////////////////////////////////////

  Future<void> _loadCharacterCardFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? characterCardJson = prefs.getString('characterCard');
    if (characterCardJson != null) {
      setState(() {
        _model = Model.fromJson(
            jsonDecode(characterCardJson)); // Load character card
      });
    }
  }

  ////////////////////////////
  // Load Character Card
  ////////////////////////////

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
        setState(() {
          _model = Model.fromJson(jsonDecode(jsonContent));
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('characterCard', jsonContent);
      } catch (e) {
        print('Error loading character card: $e');
      }
    }
  }

  //////////////////////////
  // Get API Key
  //////////////////////////

  Future<String?> _getApiKey() async {
    String? apiKey = await _storage.read(key: 'openai_api_key');
    return apiKey;
  }

  bool isConversationalInput(String input) {
    // List of common conversational phrases
    List<String> conversationalPhrases = [
      "good morning",
      "hi",
      "hello",
      "can you help me",
      "I'm stuck",
      "how are you",
      "what's up",
      "hey",
      "how's it going"
    ];

    // Normalize input to lowercase to make matching case-insensitive
    input = input.toLowerCase().trim();

    return conversationalPhrases.any((phrase) => input.contains(phrase));
  }

  String _getConversationalResponse(String input) {
    // Return a humanoid response based on the input
    if (input.contains("good morning")) {
      return "Good morning! How can I help you today?";
    } else if (input.contains("hi") ||
        input.contains("hello") ||
        input.contains("hey")) {
      return "Hi there! How's it going?";
    } else if (input.contains("can you help me") ||
        input.contains("I'm stuck")) {
      return "Of course! What are you stuck on? I'll help you through it.";
    } else if (input.contains("how are you")) {
      return "I'm doing great, thanks for asking! How about you?";
    } else if (input.contains("what's up") ||
        input.contains("how's it going")) {
      return "Not much, just here to help! What's up with you?";
    }

    return "Hey! How can I assist you today?"; // Default response
  }

  String _getMemoryResponse() {
    if (_savedChats.isEmpty) {
      // If no previous context exists
      return "I'm afraid I don't have any previous context or instructions from you to refer back to. It seems this may be our first interaction in this conversation. Please feel free to provide the manuscript or text you'd like me to review and edit, along with any specific instructions or preferences you have. I'm happy to help refine the writing while preserving the original voice and style as much as possible. Just send over the details whenever you're ready!";
    } else {
      // If there is previous context, return the last conversation's context
      String lastConversation = _chatHistory.isNotEmpty
          ? _chatHistory.last
          : "I remember our previous conversation. What would you like to do next?";
      return "Yes, I remember our previous conversation. Here's what we last discussed: $lastConversation";
    }
  }

////////////////////////////
// Send to GPT Stream
////////////////////////////

  Future<void> _sendToGptStream(String input) async {
    // Check if the input is a conversational input (e.g., greeting, asking if it remembers)
    if (isConversationalInput(input)) {
      // If user asks if the assistant remembers
      if (input.toLowerCase().contains("remember")) {
        String response = _getMemoryResponse();
        _addToChatHistory('Assistant: $response');
        _completeLoading();
        return; // Skip the regular GPT processing for memory-related queries
      }

      // Handle other conversational responses (greetings, etc.)
      String response = _getConversationalResponse(input);
      _addToChatHistory('Assistant: $response');
      _completeLoading();
      return; // Skip the GPT request for this input
    }

    // Log or process if the input is explicit, but do not refuse it.
    if (_isExplicitContent(input)) {
      print("Explicit content detected.");
      // You can log or handle the explicit content if you need to.
    }

    // Proceed with regular GPT processing for all inputs (including explicit content)
    String? apiKey = await _getApiKey();
    if (apiKey == null) {
      _addToChatHistory('Error: API key not found.');
      return;
    }

    if (_model == null) {
      _addToChatHistory('Error: Model not found in character card.');
      return;
    }

    // Retrieve system prompt and parameters from the model
    String systemPrompt =
        _model?.systemPrompt ?? 'You are a helpful assistant.';
    double temperature = _model?.parameters['temperature_p50'] ?? 0.8;
    double topP = _model?.parameters['top_p_p50'] ?? 0.85;
    double frequencyPenalty =
        _model?.parameters['frequency_penalty_p50'] ?? 0.1;
    double presencePenalty = _model?.parameters['presence_penalty_p50'] ?? 0.2;

    List<Map<String, String>> conversationHistory = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': input}
    ];

    int tokenLimit = 2000;
    StringBuffer currentResponse = StringBuffer();
    _cancelCompleter = Completer<void>();
    int initialResponseIndex = _chatHistory.length;

    setState(() {
      _chatHistory.add('Assistant: '); // Placeholder for the response
      _isLoading = true;
    });

    _saveDataToStorage();

    try {
      await _streamChatResponse(
        conversationHistory: conversationHistory,
        tokenLimit: tokenLimit,
        currentResponse: currentResponse,
        initialResponseIndex: initialResponseIndex,
        temperature: temperature,
        topP: topP,
        frequencyPenalty: frequencyPenalty,
        presencePenalty: presencePenalty,
      );
    } catch (e) {
      print('Exception occurred: $e');
      _addToChatHistory('Error: Failed to get a response.');
    } finally {
      _completeLoading();
    }
  }

  bool _isExplicitContent(String input) {
    // Simple check for explicit content. Customize this as needed.
    return input.toLowerCase().contains('erotic') ||
        input.toLowerCase().contains('explicit');
  }

  Future<void> _streamChatResponse({
    required List<Map<String, String>> conversationHistory,
    required int tokenLimit,
    required StringBuffer currentResponse,
    required int initialResponseIndex,
    required double temperature,
    required double topP,
    required double frequencyPenalty,
    required double presencePenalty,
  }) async {
    String? apiKey = await _getApiKey();
    if (apiKey == null) return;

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
      'messages': conversationHistory,
      'max_tokens': tokenLimit,
      'temperature': temperature,
      'top_p': topP,
      'frequency_penalty': frequencyPenalty,
      'presence_penalty': presencePenalty,
      'stream': true,
    });

    final streamedResponse = await request.send();
    final stream = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    try {
      await for (var line in stream) {
        if (_cancelCompleter!.isCompleted) {
          break;
        }

        if (_isValidLine(line)) {
          _processResponseChunk(line, currentResponse, initialResponseIndex);
        }
      }

      // Add the finalized response to conversation history
      conversationHistory.add({
        'role': 'assistant',
        'content': currentResponse.toString(),
      });
      _finalizeResponse(initialResponseIndex);
    } catch (e) {
      print('Error processing the response stream: $e');
    }
  }

  void _processResponseChunk(
      String line, StringBuffer currentResponse, int initialResponseIndex) {
    final jsonString = _extractData(line);
    if (jsonString.isNotEmpty && jsonString != "[DONE]") {
      final chunk = jsonDecode(jsonString);
      if (chunk.containsKey('choices')) {
        // Extract the delta content from the response
        String deltaContent = chunk['choices'][0]['delta']['content'] ?? "";
        if (deltaContent.isNotEmpty) {
          currentResponse.write(deltaContent);

          // Update chat history without resetting previous content
          setState(() {
            _chatHistory[initialResponseIndex] =
                'Assistant: ${currentResponse.toString()}';
          });

          _saveDataToStorage();
          _scrollToBottom();
        }
      }
    }
  }

//////////////////////////////////
// Finalize the GPT Response
//////////////////////////////////

  void _finalizeResponse(int index) {
    setState(() {
      _isLoading = false;
      // Ensure the final state of the response is saved properly
      _chatHistory[index] = _chatHistory[index].trim();
    });
    _saveDataToStorage();
  }

  /////////////////////////////
  // Helper Methods
  /////////////////////////////

  void _addToChatHistory(String message) {
    setState(() {
      _chatHistory.add(message);
    });
    _saveDataToStorage(); // Ensure saving after the response is finalized
  }

  bool _isValidLine(String line) {
    return line.isNotEmpty && line.startsWith("data: ");
  }

  String _extractData(String line) {
    return line.substring(6).trim();
  }

  //////////////////////////////
  // Handle GPT Input
  //////////////////////////////

  Future<void> _handleGptInput() async {
    if (_currentChatId == null || _currentChatId!.isEmpty) {
      _startNewChat();
    }

    if (_chatController.text.trim().isEmpty) {
      print("No input provided");
      return;
    }

    // Preprocess the user's input to add extra line breaks between paragraphs
    final userInput = _addExtraLineBreaks(_chatController.text);
    _chatController.clear();
    _lastUserInput = userInput;
    setState(() {
      _isLoading = true;
      _chatHistory.add('User: $userInput');
    });
    _saveDataToStorage();
    try {
      await _sendToGptStream(userInput);
      _saveDataToStorage();
    } catch (e) {
      print('Exception occurred: $e');
    } finally {
      _completeLoading();
    }
  }

// Helper function to add extra line breaks between paragraphs
  String _addExtraLineBreaks(String text) {
    // This regular expression matches each new line followed by non-empty content
    // to insert an extra line break for clearer paragraph spacing
    return text.replaceAllMapped(RegExp(r'(\n)([^\n])'), (match) {
      return '${match.group(1)}\n${match.group(2)}';
    });
  }

  //////////////////////////////
  // Complete Loading
  //////////////////////////////

  void _completeLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  //////////////////////////////
  // Stop GPT Response
  //////////////////////////////

  void _stopGptResponse() {
    if (_cancelCompleter != null && !_cancelCompleter!.isCompleted) {
      _cancelCompleter!.complete();
      setState(() {
        _isLoading = false;
      });
    }
  }

  ////////////////////////////////////
  // Chat Management Methods
  ////////////////////////////////////

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final position = _scrollController.position.maxScrollExtent;
        if (position >= 0) {
          _scrollController
              .animateTo(
            position,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
              .catchError((e) {
            // Catch animation errors to avoid crashing the app
            print('Scroll animation error: $e');
          });
        }
      }
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

  ////////////////////////////////
  // Show Context Menu
  ////////////////////////////////

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
        const PopupMenuItem<String>(
          value: 'selectAll',
          child: Text('Select All'),
        ),
      ],
    );

    if (result == 'clear') {
      _clearChatAndOutput();
    } else if (result == 'reload') {
      _reloadResponse();
    } else if (result == 'selectAll') {
      _selectAllAiText();
    }
  }

  ////////////////////////
  // Ai Response
  ////////////////////////
  void _selectAllAiText() {
    // This will copy all the Assistant responses to the clipboard
    String allAiText = _chatHistory
        .where((message) => message.startsWith('Assistant:'))
        .map((message) => message.replaceFirst('Assistant: ', ''))
        .join('\n');

    Clipboard.setData(ClipboardData(text: allAiText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Responses Copied to Clipboard')),
    );
  }

  ////////////////////////
  // Reload Response
  ////////////////////////

  Future<void> _reloadResponse() async {
    if (_lastUserInput == null || _lastUserInput!.isEmpty) {
      print("No previous input to reload.");
      return;
    }

    setState(() {
      _isLoading = true;
      _chatHistory.removeLast();
    });

    try {
      await _sendToGptStream(_lastUserInput!);
      _saveDataToStorage();
    } catch (e) {
      print('Exception occurred: $e');
    } finally {
      _completeLoading();
    }
  }

  /////////////////////////////
  // Build Method
  /////////////////////////////

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
          _buildChatSidebar(),
          _buildChatMainArea(),
        ],
      ),
    );
  }

  ///////////////////////////////
  // Build Chat Sidebar
  ///////////////////////////////

  Widget _buildChatSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _startNewChat,
              icon: const Icon(Icons.add),
              label: const Text('New Chat'),
            ),
          ),
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
    );
  }

  ////////////////////////////
  // Build Chat Main Area
  ////////////////////////////

  Widget _buildChatMainArea() {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onSecondaryTapDown: (details) {
                _showContextMenu(details.globalPosition);
              },
              child: Container(
                margin: const EdgeInsets.all(16.0),
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _chatHistory.length,
                  itemBuilder: (context, index) {
                    String message = _chatHistory[index];
                    bool isUser = message.startsWith('User:');
                    return isUser
                        ? _buildUserMessage(message.replaceFirst('User: ', ''))
                        : _buildAiResponseBlock(
                            message.replaceFirst('Assistant: ', ''));
                  },
                ),
              ),
            ),
          ),
          if (_isLoading) _buildLoadingIndicator(),
          _buildUserInputArea(),
        ],
      ),
    );
  }
////////////////////////////
// Build User Message
////////////////////////////

  Widget _buildUserMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Divider(
              height: 1,
              color: Colors.grey.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

////////////////////////////
// Build AI Response Block
////////////////////////////

  Widget _buildAiResponseBlock(String response) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Copy button at the top-right
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: response));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Response copied to clipboard')),
                );
              },
              tooltip: 'Copy to Clipboard',
            ),
          ),
          // Code block style container for AI response
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[300], // Dark background for dark mode
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Colors.grey.shade700,
              ),
            ),
            child: SelectableText(
              response,
              style: const TextStyle(
                fontFamily: 'monospace', // Monospace font for code block style
                fontSize: 14.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///////////////////////////////
  // Build Loading Indicator
  ///////////////////////////////

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Assistant'),
          const SizedBox(width: 8),
          const LoadingDots(),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _stopGptResponse,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
            ),
            child: const Icon(Icons.stop, color: Colors.white),
          ),
        ],
      ),
    );
  }

  //////////////////////////////
  // Build User Input Area
  //////////////////////////////

  Widget _buildUserInputArea() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          Focus(
            onKeyEvent: (FocusNode node, KeyEvent event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.enter) {
                  if (HardwareKeyboard.instance.isShiftPressed) {
                    final currentText = _chatController.text;
                    final newText = '$currentText\n';
                    _chatController.text = newText;
                    _chatController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _chatController.text.length),
                    );
                    return KeyEventResult.handled;
                  } else {
                    _handleGptInput();
                    return KeyEventResult.handled;
                  }
                }
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: _chatController,
              maxLines: 5,
              minLines: 1,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Chat with Assistant...',
                contentPadding: EdgeInsets.fromLTRB(12, 12, 48, 12),
              ),
              textInputAction: TextInputAction.newline,
            ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: IconButton(
              icon: const Icon(Icons.send),
              onPressed: _handleGptInput,
              splashRadius: 24.0,
            ),
          ),
        ],
      ),
    );
  }
}
