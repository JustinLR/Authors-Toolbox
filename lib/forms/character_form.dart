import 'package:flutter/material.dart';
import 'package:authors_toolbox/models/character.dart';

class CharacterForm extends StatefulWidget {
  final Function(Character) onSave;
  final Character? editingCharacter; // If editing, pass the character here

  CharacterForm({required this.onSave, this.editingCharacter});

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
            SizedBox(height: 20),
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
            SizedBox(height: 20),
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
              child: Text('Save Character'),
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
        border: OutlineInputBorder(),
      ),
      onSaved: onSaved,
      validator: validator,
      keyboardType: keyboardType,
    );
  }
}
