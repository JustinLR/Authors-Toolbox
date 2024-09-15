import 'package:flutter/material.dart';
import 'package:authors_toolbox/models/character.dart';

class CharacterForm extends StatefulWidget {
  final Function(Character) onSave;
  final Character? editingCharacter; // If editing, pass the character here

  const CharacterForm({super.key, required this.onSave, this.editingCharacter});

  @override
  _CharacterFormState createState() => _CharacterFormState();
}

class _CharacterFormState extends State<CharacterForm> {
  final _formKey = GlobalKey<FormState>();
  late Character _character;

  @override
  void initState() {
    super.initState();
    // If editing, populate the form with existing data
    _character =
        widget.editingCharacter ?? Character(name: '', age: 0, role: 'Hero');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            _buildTextInputField(
              labelText: 'Character Name',
              initialValue: _character.name,
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
            const SizedBox(height: 20),
            _buildTextInputField(
              labelText: 'Character Age',
              initialValue: _character.age.toString(),
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
            const SizedBox(height: 20),
            _buildTextInputField(
              labelText: 'Gender',
              initialValue: _character.gender,
              onSaved: (value) {
                _character.gender = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Race',
              initialValue: _character.race,
              onSaved: (value) {
                _character.race = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Occupation',
              initialValue: _character.occupation,
              onSaved: (value) {
                _character.occupation = value;
              },
            ),
            const SizedBox(height: 20),

            // Dropdown for Role
            DropdownButtonFormField<String>(
              value: _character.role,
              decoration: const InputDecoration(
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
            const SizedBox(height: 20),

            // Physical Appearance
            Text(
              'Physical Appearance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            _buildTextInputField(
              labelText: 'Height',
              initialValue: _character.height,
              onSaved: (value) {
                _character.height = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Weight',
              initialValue: _character.weight,
              onSaved: (value) {
                _character.weight = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Build',
              initialValue: _character.build,
              onSaved: (value) {
                _character.build = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Hair',
              initialValue: _character.hair,
              onSaved: (value) {
                _character.hair = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Eyes',
              initialValue: _character.eyes,
              onSaved: (value) {
                _character.eyes = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Skin',
              initialValue: _character.skin,
              onSaved: (value) {
                _character.skin = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Clothing Style',
              initialValue: _character.clothingStyle,
              onSaved: (value) {
                _character.clothingStyle = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Physical Traits',
              initialValue: _character.physicalTraits,
              onSaved: (value) {
                _character.physicalTraits = value;
              },
            ),
            const SizedBox(height: 20),

            // Powers and Abilities
            Text(
              'Powers and Abilities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SwitchListTile(
              title: const Text('Has Powers'),
              value: _character.hasPowers,
              onChanged: (value) {
                setState(() {
                  _character.hasPowers = value;
                });
              },
            ),
            if (_character.hasPowers) ...[
              _buildTextInputField(
                labelText: 'Power Type',
                initialValue: _character.powerType,
                onSaved: (value) {
                  _character.powerType = value;
                },
              ),
              _buildTextInputField(
                labelText: 'Power Origin',
                initialValue: _character.powerOrigin,
                onSaved: (value) {
                  _character.powerOrigin = value;
                },
              ),
            ],

            // Skills, Weapons, and Weaknesses
            _buildTextInputField(
              labelText: 'Skills',
              initialValue: _character.skills?.join(', '),
              onSaved: (value) {
                _character.skills =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Weapons',
              initialValue: _character.weapons?.join(', '),
              onSaved: (value) {
                _character.weapons =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Weaknesses',
              initialValue: _character.weaknesses?.join(', '),
              onSaved: (value) {
                _character.weaknesses =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            const SizedBox(height: 20),

            // Psychological Traits
            Text(
              'Psychological Traits',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            _buildTextInputField(
              labelText: 'Motivation',
              initialValue: _character.motivation,
              onSaved: (value) {
                _character.motivation = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Fears',
              initialValue: _character.fears?.join(', '),
              onSaved: (value) {
                _character.fears =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Likes',
              initialValue: _character.likes?.join(', '),
              onSaved: (value) {
                _character.likes =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Dislikes',
              initialValue: _character.dislikes?.join(', '),
              onSaved: (value) {
                _character.dislikes =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Ticks/Quirks',
              initialValue: _character.ticksOrQuirks?.join(', '),
              onSaved: (value) {
                _character.ticksOrQuirks =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Moral Alignment',
              initialValue: _character.moralAlignment,
              onSaved: (value) {
                _character.moralAlignment = value;
              },
            ),
            const SizedBox(height: 20),

            // Backstory
            Text(
              'Backstory',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            _buildTextInputField(
              labelText: 'Birthplace',
              initialValue: _character.birthplace,
              onSaved: (value) {
                _character.birthplace = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Backstory Summary',
              initialValue: _character.backstorySummary,
              onSaved: (value) {
                _character.backstorySummary = value;
              },
            ),
            _buildTextInputField(
              labelText: 'Key Life Events',
              initialValue: _character.keyLifeEvents?.join(', '),
              onSaved: (value) {
                _character.keyLifeEvents =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Education/Training',
              initialValue: _character.educationOrTraining,
              onSaved: (value) {
                _character.educationOrTraining = value;
              },
            ),
            const SizedBox(height: 20),

            // Relationships
            Text(
              'Relationships',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            _buildTextInputField(
              labelText: 'Family',
              initialValue: _character.family?.join(', '),
              onSaved: (value) {
                _character.family =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Romantic Relationships',
              initialValue: _character.romanticRelationships?.join(', '),
              onSaved: (value) {
                _character.romanticRelationships =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Friends and Allies',
              initialValue: _character.friendsAndAllies?.join(', '),
              onSaved: (value) {
                _character.friendsAndAllies =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Enemies',
              initialValue: _character.enemies?.join(', '),
              onSaved: (value) {
                _character.enemies =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            _buildTextInputField(
              labelText: 'Pets',
              initialValue: _character.pets?.join(', '),
              onSaved: (value) {
                _character.pets =
                    value?.split(',').map((s) => s.trim()).toList();
              },
            ),
            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  widget.onSave(_character);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Character Saved: ${_character.name}'),
                    ),
                  );
                }
              },
              child: const Text('Save Character'),
            ),
          ],
        ),
      ),
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
