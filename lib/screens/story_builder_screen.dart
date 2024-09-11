import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Import forms and widgets
import 'package:authors_toolbox/forms/character_form.dart';
import 'package:authors_toolbox/forms/location_form.dart';
import 'package:authors_toolbox/widgets/saved_entities_list.dart';

// Import the models
import 'package:authors_toolbox/models/character.dart';
import 'package:authors_toolbox/models/location.dart';

class StoryBuilderScreen extends StatefulWidget {
  @override
  _StoryBuilderScreenState createState() => _StoryBuilderScreenState();
}

class _StoryBuilderScreenState extends State<StoryBuilderScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  // Lists for saved data
  List<Character> _savedCharacters = [];
  List<Location> _savedLocations = [];

  // For editing mode
  Character? _editingCharacter;
  Location? _editingLocation;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedData();
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
      if (_editingCharacter != null && _editingIndex != null) {
        _savedCharacters[_editingIndex!] = character; // Edit mode
        _editingCharacter = null;
        _editingIndex = null;
      } else {
        _savedCharacters.add(character);
      }
    });
    _saveData();
  }

  // Add a new location to the saved list
  void _addLocation(Location location) {
    setState(() {
      if (_editingLocation != null && _editingIndex != null) {
        _savedLocations[_editingIndex!] = location; // Edit mode
        _editingLocation = null;
        _editingIndex = null;
      } else {
        _savedLocations.add(location);
      }
    });
    _saveData();
  }

  // Remove a character from the saved list
  void _deleteCharacter(int index) {
    setState(() {
      _savedCharacters.removeAt(index);
    });
    _saveData();
  }

  // Remove a location from the saved list
  void _deleteLocation(int index) {
    setState(() {
      _savedLocations.removeAt(index);
    });
    _saveData();
  }

  // Edit an existing character
  void _editCharacter(int index) {
    setState(() {
      _editingCharacter = _savedCharacters[index];
      _editingIndex = index;
      _tabController!.animateTo(0); // Switch to character tab
    });
  }

  // Edit an existing location
  void _editLocation(int index) {
    setState(() {
      _editingLocation = _savedLocations[index];
      _editingIndex = index;
      _tabController!.animateTo(1); // Switch to location tab
    });
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
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: TabBarView(
              controller: _tabController,
              children: [
                CharacterForm(
                  onSave: _addCharacter,
                  editingCharacter: _editingCharacter,
                ),
                LocationForm(
                  onSave: _addLocation,
                  editingLocation: _editingLocation,
                ),
              ],
            ),
          ),
          VerticalDivider(),
          Expanded(
            flex: 2,
            child: TabBarView(
              controller: _tabController,
              children: [
                SavedEntitiesList<Character>(
                  entities: _savedCharacters,
                  onDelete: _deleteCharacter,
                  onEdit: _editCharacter,
                  getTitle: (character) => character.name,
                  getSubtitle: (character) =>
                      'Age: ${character.age}, Role: ${character.role}',
                ),
                SavedEntitiesList<Location>(
                  entities: _savedLocations,
                  onDelete: _deleteLocation,
                  onEdit: _editLocation,
                  getTitle: (location) => location.name,
                  getSubtitle: (location) => location.description,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
