import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart'; // Import the AppNavigationDrawer

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      drawer:
          AppNavigationDrawer(), // Attach the navigation drawer to the Home Page
      body: Center(
        child: Text(
          'Welcome to Authors Toolbox!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
