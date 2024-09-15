// lib/screens/overlay_menu.dart
import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';

class OverlayMenu extends StatelessWidget {
  const OverlayMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authors Toolbox'),
      ),
      drawer:
          const AppNavigationDrawer(), // Assuming you renamed your NavigationDrawer to AppNavigationDrawer
      body: const Center(
        child: Text('Select a module from the drawer'),
      ),
    );
  }
}
