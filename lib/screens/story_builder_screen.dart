import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';

// Import the models
import 'package:authors_toolbox/models/character.dart';
import 'package:authors_toolbox/models/location.dart';

class StoryBuilderScreen extends StatefulWidget {
  @override
  _StoryBuilderScreenState createState() => _StoryBuilderScreenState();
}

class _StoryBuilderScreenState extends State<StoryBuilderScreen>
    with SingleTickerProviderStateMixin {
  final _characterFormKey = GlobalKey<FormState>();
  final _locationFormKey = GlobalKey<FormState>();

  TabController? _tabController;

  // Model instances for each type
  Character _character = Character(name: '', age: 0, role: 'Hero');
  Location _location = Location(name: '', description: '');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Story Builder'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Character'),
            Tab(text: 'Location'),
          ],
        ),
      ),
      drawer: AppNavigationDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCharacterForm(),
          _buildLocationForm(),
        ],
      ),
    );
  }

  // Character Form
  Widget _buildCharacterForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _characterFormKey,
        child: ListView(
          children: [
            Text(
              'Create a New Character',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20),
            _buildTextInputField(
              labelText: 'Character Name',
              onSaved: (value) {
                _character.name = value!;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            _buildTextInputField(
              labelText: 'Character Age',
              keyboardType: TextInputType.number,
              onSaved: (value) {
                _character.age = int.parse(value!);
              },
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
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _character.role,
              decoration: InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: ['Hero', 'Villain', 'Sidekick'].map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _character.role = value!;
                });
              },
            ),
            SizedBox(height: 20),
            _buildTextInputField(
              labelText: 'Personality (Optional)',
              onSaved: (value) {
                _character.personality = value;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_characterFormKey.currentState!.validate()) {
                  _characterFormKey.currentState!.save();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Character Created: ${_character.name}'),
                    ),
                  );
                }
              },
              child: Text('Save Character'),
            ),
          ],
        ),
      ),
    );
  }

  // Location Form
  Widget _buildLocationForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _locationFormKey,
        child: ListView(
          children: [
            Text(
              'Create a New Location',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20),
            _buildTextInputField(
              labelText: 'Location Name',
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
            SizedBox(height: 20),
            _buildTextInputField(
              labelText: 'Description',
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_locationFormKey.currentState!.validate()) {
                  _locationFormKey.currentState!.save();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Location Created: ${_location.name}'),
                    ),
                  );
                }
              },
              child: Text('Save Location'),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Text Input Field Widget
  Widget _buildTextInputField({
    required String labelText,
    required FormFieldSetter<String> onSaved,
    FormFieldValidator<String>? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
      ),
      onSaved: onSaved,
      validator: validator,
      keyboardType: keyboardType,
    );
  }
}
