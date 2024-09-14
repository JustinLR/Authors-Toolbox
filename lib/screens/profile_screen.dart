import 'package:flutter/material.dart';
import 'dart:io'; // For using File
import 'package:image_picker/image_picker.dart'; // For picking images

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers for text fields
  TextEditingController _nameController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  // Variable for storing the profile picture path
  File? _profilePicture;

  // A key to validate the form
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Picture
                GestureDetector(
                  onTap: _changeProfilePicture,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profilePicture != null
                        ? FileImage(
                            _profilePicture!) // Display the selected image
                        : null, // No image (will leave it blank)
                    child: _profilePicture == null
                        ? Icon(Icons.person,
                            size:
                                50) // Show an icon if no profile picture is selected
                        : null, // If profile picture is selected, don't show the icon
                  ),
                ),
                SizedBox(height: 16),
                Text('Tap to change profile picture',
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 24),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    } else if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: Text('Save Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Dummy function to save profile information
  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // You can replace this with actual logic to save the profile information
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile Saved!'),
      ));
    }
  }

  // Function to change profile picture using image_picker
  Future<void> _changeProfilePicture() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profilePicture = File(image.path); // Use File() to wrap the image path
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
