// lib/screens/overlay_menu.dart
import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';

class OverlayMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Authors Toolbox'),
      ),
      drawer:
          AppNavigationDrawer(), // Assuming you renamed your NavigationDrawer to AppNavigationDrawer
      body: Center(
        child: Text('Select a module from the drawer'),
      ),
    );
  }
}
