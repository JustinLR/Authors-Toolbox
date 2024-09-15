import 'package:flutter/material.dart';

class SavedEntitiesList<T> extends StatelessWidget {
  final List<T> entities;
  final Function(int) onDelete;
  final Function(int) onEdit; // Add this line for edit callback
  final String Function(T) getTitle;
  final String Function(T) getSubtitle;

  const SavedEntitiesList({
    super.key,
    required this.entities,
    required this.onDelete,
    required this.onEdit, // Add this line
    required this.getTitle,
    required this.getSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (entities.isEmpty) {
      return const Center(
        child: Text('No saved items'),
      );
    }

    return ListView.builder(
      itemCount: entities.length,
      itemBuilder: (context, index) {
        final entity = entities[index];
        return ListTile(
          title: Text(getTitle(entity)),
          subtitle: Text(getSubtitle(entity)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit), // Edit button
                onPressed: () => onEdit(index), // Trigger edit callback
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => onDelete(index), // Trigger delete callback
              ),
            ],
          ),
        );
      },
    );
  }
}
