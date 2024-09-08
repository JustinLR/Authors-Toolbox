import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart'; // Import the AppNavigationDrawer

class ThesaurusScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thesaurus'),
      ),
      drawer: AppNavigationDrawer(), // Attach the navigation drawer
      body: Center(
        child: Text('Thesaurus content goes here'),
      ),
    );
  }
}
