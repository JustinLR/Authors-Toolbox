import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding/decoding

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

  // Model instances for forms
  Character _character = Character(name: '', age: 0, role: 'Hero');
  Location _location = Location(name: '', description: '');

  // Lists for saved data
  List<Character> _savedCharacters = [];
  List<Location> _savedLocations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedData(); // Load both characters and locations from SharedPreferences
  }

  // Load saved characters and locations from SharedPreferences
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved characters
    final List<String>? savedCharactersJson = prefs.getStringList('characters');
    if (savedCharactersJson != null) {
      setState(() {
        _savedCharacters = savedCharactersJson
            .map((characterJson) =>
                Character.fromJson(jsonDecode(characterJson)))
            .toList();
      });
    }

    // Load saved locations
    final List<String>? savedLocationsJson = prefs.getStringList('locations');
    if (savedLocationsJson != null) {
      setState(() {
        _savedLocations = savedLocationsJson
            .map((locationJson) => Location.fromJson(jsonDecode(locationJson)))
            .toList();
      });
    }
  }

  // Save both characters and locations to SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save characters
    final List<String> charactersJson = _savedCharacters
        .map((character) => jsonEncode(character.toJson()))
        .toList();
    await prefs.setStringList('characters', charactersJson);

    // Save locations
    final List<String> locationsJson = _savedLocations
        .map((location) => jsonEncode(location.toJson()))
        .toList();
    await prefs.setStringList('locations', locationsJson);
  }

  // Add a new character to the saved list
  void _addCharacter(Character character) {
    setState(() {
      _savedCharacters.add(character);
    });
    _saveData(); // Save after adding
  }

  // Add a new location to the saved list
  void _addLocation(Location location) {
    setState(() {
      _savedLocations.add(location);
    });
    _saveData(); // Save after adding
  }

  // Remove a character from the saved list
  void _deleteCharacter(int index) {
    setState(() {
      _savedCharacters.removeAt(index);
    });
    _saveData(); // Save after deletion
  }

  // Remove a location from the saved list
  void _deleteLocation(int index) {
    setState(() {
      _savedLocations.removeAt(index);
    });
    _saveData(); // Save after deletion
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
      // Include the navigation drawer
      drawer:
          AppNavigationDrawer(), // Assuming AppNavigationDrawer is defined elsewhere
      body: Row(
        children: [
          // Left: Form for creating characters/locations
          Expanded(
            flex: 3,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCharacterForm(),
                _buildLocationForm(),
              ],
            ),
          ),

          VerticalDivider(),
          // Right: List of saved characters/locations
          Expanded(
            flex: 2,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSavedCharactersList(),
                _buildSavedLocationsList(),
              ],
            ),
          ),
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
              labelText: 'Personality ',
              onSaved: (value) {
                _character.personality = value;
              },
            ),
            SizedBox(height: 20),
            // Add Gender, Race, and Occupation
            _buildTextInputField(
              labelText: 'Gender ',
              onSaved: (value) {
                _character.gender = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Race ',
              onSaved: (value) {
                _character.race = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Occupation ',
              onSaved: (value) {
                _character.occupation = value;
              },
            ),
            SizedBox(height: 20),

            // Physical Appearance
            Text(
              'Physical Appearance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            _buildTextInputField(
              labelText: 'Height ',
              onSaved: (value) {
                _character.height = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Weight ',
              onSaved: (value) {
                _character.weight = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Build ',
              onSaved: (value) {
                _character.build = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Hair ',
              onSaved: (value) {
                _character.hair = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Eyes ',
              onSaved: (value) {
                _character.eyes = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Skin ',
              onSaved: (value) {
                _character.skin = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Clothing Style ',
              onSaved: (value) {
                _character.clothingStyle = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Physical Traits ',
              onSaved: (value) {
                _character.physicalTraits = value;
              },
            ),
            SizedBox(height: 20),

            // Powers and Abilities
            Text(
              'Powers and Abilities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SwitchListTile(
              title: Text('Has Powers'),
              value: _character.hasPowers,
              onChanged: (value) {
                setState(() {
                  _character.hasPowers = value;
                });
              },
            ),
            if (_character.hasPowers) ...[
              _buildTextInputField(
                labelText: 'Power Type ',
                onSaved: (value) {
                  _character.powerType = value;
                },
              ),
              _buildTextInputField(
                labelText: 'Power Origin ',
                onSaved: (value) {
                  _character.powerOrigin = value;
                },
              ),
            ],

            // Skills, Weapons, and Weaknesses
            _buildTextInputField(
              labelText: 'Skills ',
              onSaved: (value) {
                _character.skills =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Weapons ',
              onSaved: (value) {
                _character.weapons =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Weaknesses ',
              onSaved: (value) {
                _character.weaknesses =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            SizedBox(height: 20),

            // Psychological Traits
            Text(
              'Psychological Traits',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            _buildTextInputField(
              labelText: 'Motivation ',
              onSaved: (value) {
                _character.motivation = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Fears ',
              onSaved: (value) {
                _character.fears =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Likes ',
              onSaved: (value) {
                _character.likes =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Dislikes ',
              onSaved: (value) {
                _character.dislikes =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Ticks/Quirks ',
              onSaved: (value) {
                _character.ticksOrQuirks =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Moral Alignment ',
              onSaved: (value) {
                _character.moralAlignment = value;
              },
            ),

            // Backstory
            Text(
              'Backstory',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            _buildTextInputField(
              labelText: 'Birthplace ',
              onSaved: (value) {
                _character.birthplace = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Backstory Summary ',
              onSaved: (value) {
                _character.backstorySummary = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Key Life Events ',
              onSaved: (value) {
                _character.keyLifeEvents =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Education/Training ',
              onSaved: (value) {
                _character.educationOrTraining = value;
              },
            ),

            // Relationships
            Text(
              'Relationships',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            _buildTextInputField(
              labelText: 'Family ',
              onSaved: (value) {
                _character.family =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Romantic Relationships ',
              onSaved: (value) {
                _character.romanticRelationships =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Friends and Allies ',
              onSaved: (value) {
                _character.friendsAndAllies =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Enemies ',
              onSaved: (value) {
                _character.enemies =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Pets ',
              onSaved: (value) {
                _character.pets =
                    value?.split(',').map((s) => s.trim()).toList();
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

  // Saved Characters List
  Widget _buildSavedCharactersList() {
    if (_savedCharacters.isEmpty) {
      return Center(
        child: Text('No saved characters'),
      );
    }

    return ListView.builder(
      itemCount: _savedCharacters.length,
      itemBuilder: (context, index) {
        final character = _savedCharacters[index];
        return ListTile(
          title: Text(character.name),
          subtitle: Text('Age: ${character.age}, Role: ${character.role}'),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteCharacter(index),
          ),
        );
      },
    );
  }

  // Saved Locations List
  Widget _buildSavedLocationsList() {
    if (_savedLocations.isEmpty) {
      return Center(
        child: Text('No saved locations'),
      );
    }

    return ListView.builder(
      itemCount: _savedLocations.length,
      itemBuilder: (context, index) {
        final location = _savedLocations[index];
        return ListTile(
          title: Text(location.name),
          subtitle: Text('Description: ${location.description}'),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteLocation(index),
          ),
        );
      },
    );
  }

  // Location Form (same as previous version)
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
