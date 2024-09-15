import 'package:flutter/material.dart';
import 'package:authors_toolbox/models/location.dart';

class LocationForm extends StatefulWidget {
  final Function(Location) onSave;
  final Location? editingLocation; // If editing, pass the location here

  const LocationForm({super.key, required this.onSave, this.editingLocation});

  @override
  _LocationFormState createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm> {
  final _formKey = GlobalKey<FormState>();
  late Location _location;

  // State to manage chat and saved locations
  TextEditingController _gptController = TextEditingController();
  List<Location> _savedLocations = [
    Location(
        name: 'Mystic Forest',
        description: 'A forest full of ancient secrets.'),
    Location(
        name: 'Crystal Lake', description: 'A lake with shimmering waters.'),
  ];

  List<Map<String, String>> _chatMessages = [
    {'User': 'Help me create a location'},
    {'GPT': 'What kind of location would you like to create?'},
  ];

  @override
  void initState() {
    super.initState();
    _location = widget.editingLocation ?? Location(name: '', description: '');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: Location Form
        Expanded(
          flex: 2, // Takes 2/3 of the screen
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Text(
                    widget.editingLocation != null
                        ? 'Edit Location'
                        : 'Create a New Location',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  _buildTextInputField(
                    labelText: 'Location Name',
                    initialValue: _location.name,
                    onSaved: (value) {
                      _location.name = value!;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the location name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextInputField(
                    labelText: 'Description',
                    initialValue: _location.description,
                    onSaved: (value) {
                      _location.description = value!;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please describe the location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        widget.onSave(_location);
                        setState(() {
                          _savedLocations
                              .add(_location); // Add location to saved list
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Location Saved: ${_location.name}')),
                        );
                      }
                    },
                    child: const Text('Save Location'),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right: Split between Chat Box (Top) and Saved Locations (Bottom)
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

              // Bottom: Saved Locations
              Expanded(
                flex: 1, // Takes up half of the right section
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saved Locations',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _savedLocations.length,
                          itemBuilder: (context, index) {
                            final location = _savedLocations[index];
                            return ListTile(
                              title: Text(location.name),
                              subtitle: Text(location.description),
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

  // Reusable text input field widget
  Widget _buildTextInputField({
    required String labelText,
    required FormFieldSetter<String> onSaved,
    FormFieldValidator<String>? validator,
    TextInputType keyboardType = TextInputType.text,
    String? initialValue,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      onSaved: onSaved,
      validator: validator,
      keyboardType: keyboardType,
    );
  }
}
