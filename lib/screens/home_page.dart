import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authors Toolbox Home'),
      ),
      drawer: const AppNavigationDrawer(), // Include the navigation drawer
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting and Quick Navigation
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'What would you like to do today?',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  // Quick Navigation Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _quickActionButton(
                        context,
                        'Book Hub',
                        Icons.book,
                        '/book_hub', // Ensure the route matches the one defined in main.dart
                      ),
                      _quickActionButton(
                        context,
                        'Progress Tracker',
                        Icons.track_changes,
                        '/progress_tracker', // Ensure this route matches
                      ),
                      _quickActionButton(
                        context,
                        'Thesaurus',
                        Icons.text_fields,
                        '/thesaurus', // Ensure this route matches
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            // Recent Activity
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _recentActivity('Reviewed: The Great Novel - Chapter 3'),
                  _recentActivity('Updated: Progress Tracker - 75% complete'),
                  _recentActivity('Checked: Synonyms for "inspiration"'),
                ],
              ),
            ),
            const Divider(),
            // Featured Tools or Tips
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Writing Tip of the Day',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '“Show, don’t tell” - Instead of saying a character is '
                    'angry, show their body language and actions that convey anger.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton(
      BuildContext context, String label, IconData icon, String route) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pushNamed(
            context, route); // Use pushNamed with the correct route
      },
      icon: Icon(icon, size: 28),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      ),
    );
  }

  Widget _recentActivity(String activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(child: Text(activity)),
        ],
      ),
    );
  }
}
