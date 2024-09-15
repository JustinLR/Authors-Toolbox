import 'package:flutter/material.dart';
import 'package:authors_toolbox/models/character.dart';

class CharacterForm extends StatefulWidget {
  final Function(Character) onSave;
  final Character? editingCharacter;

  const CharacterForm({
    super.key,
    required this.onSave,
    this.editingCharacter,
  });

  @override
  _CharacterFormState createState() => _CharacterFormState();
}

class _CharacterFormState extends State<CharacterForm> {
  final _formKey = GlobalKey<FormState>();
  late Character _character;

  // State to manage chat and saved characters
  TextEditingController _gptController = TextEditingController();
  List<Character> _savedCharacters = [
    Character(name: 'Arden', age: 30, role: 'Warrior'),
    Character(name: 'Luna', age: 22, role: 'Mage'),
  ];

  List<Map<String, String>> _chatMessages = [
    {'User': 'Help me create a character'},
    {'GPT': 'What kind of character would you like to create?'},
  ];

  @override
  void initState() {
    super.initState();
    _character =
        widget.editingCharacter ?? Character(name: '', age: 0, role: 'Hero');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: Character Form
        Expanded(
          flex: 2, // Takes 2/3 of the screen
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text(
                    widget.editingCharacter != null
                        ? 'Edit Character'
                        : 'Create a New Character',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: _character.name,
                    decoration:
                        const InputDecoration(labelText: 'Character Name'),
                    onSaved: (value) => _character.name = value!,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter a name'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    initialValue: _character.age.toString(),
                    decoration:
                        const InputDecoration(labelText: 'Character Age'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => _character.age = int.parse(value!),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the character\'s age';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _character.role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items:
                        ['Hero', 'Villain', 'Sidekick', 'Warrior'].map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _character.role = value!),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        widget.onSave(_character);
                        setState(() {
                          _savedCharacters
                              .add(_character); // Add character to saved list
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Character Saved: ${_character.name}')),
                        );
                      }
                    },
                    child: const Text('Save Character'),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right: Split between Chat Box (Top) and Saved Characters (Bottom)
        Expanded(
          flex: 1, // Takes 1/3 of the screen
          child: Column(
            children: [
              // Top: Chat Box
              Expanded(
                flex: 1, // Takes up half of the right section
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chat with GPT Assistant',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView(
                          children: _chatMessages.map((message) {
                            String user = message.keys.first;
                            String text = message[user]!;
                            return ListTile(title: Text('$user: $text'));
                          }).toList(),
                        ),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _gptController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () {
                              setState(() {
                                _chatMessages
                                    .add({'User': _gptController.text});
                                _gptController.clear();
                              });

                              // Simulate GPT response
                              Future.delayed(const Duration(seconds: 2), () {
                                setState(() {
                                  _chatMessages.add({
                                    'GPT': 'This is a simulated GPT response.'
                                  });
                                });
                              });
                            },
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom: Saved Characters
              Expanded(
                flex: 1, // Takes up half of the right section
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saved Characters',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _savedCharacters.length,
                          itemBuilder: (context, index) {
                            final character = _savedCharacters[index];
                            return ListTile(
                              title: Text(character.name),
                              subtitle: Text(
                                  'Role: ${character.role}, Age: ${character.age}'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
