import 'package:flutter/material.dart';

class SavedChatsScreen extends StatelessWidget {
  final List<String> savedChats;
  final Function(String) loadChat;
  final Function(int) deleteChat;
  final Function deleteAllChats;

  // Constructor for SavedChatsScreen with required parameters
  const SavedChatsScreen({
    super.key,
    required this.savedChats,
    required this.loadChat,
    required this.deleteChat,
    required this.deleteAllChats, // Added delete all chats function
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Chats'),
      ),
      body: Column(
        children: [
          Expanded(
            child: savedChats.isEmpty
                ? const Center(child: Text('No saved chats available.'))
                : ListView.builder(
                    itemCount: savedChats.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text('Chat Session ${index + 1}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore),
                              onPressed: () {
                                loadChat(savedChats[index]);
                                Navigator.pop(
                                    context); // Go back to the chat screen
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                deleteChat(index); // Delete individual chat
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Large "Delete All Chats" button at the bottom center
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  backgroundColor:
                      Colors.red, // Set the button color to red for prominence
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  // Confirm before deleting all chats
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete All Chats'),
                        content: const Text(
                            'Are you sure you want to delete all saved chats?'),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                          ),
                          ElevatedButton(
                            onPressed: () {
                              deleteAllChats(); // Delete all saved chats
                              Navigator.of(context).pop(); // Close the dialog
                              Navigator.of(context)
                                  .pop(); // Go back to main screen
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.red, // Confirm deletion in red
                            ),
                            child: const Text('Delete All'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text(
                  'Delete All Chats',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
