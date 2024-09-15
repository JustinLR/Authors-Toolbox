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

  @override
  void initState() {
    super.initState();
    // If editing, populate the form with existing data
    _location = widget.editingLocation ?? Location(name: '', description: '');
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Location Saved: ${_location.name}'),
                    ),
                  );
                }
              },
              child: const Text('Save Location'),
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
