import 'dart:io';
import 'package:flutter/material.dart';
import 'package:authors_toolbox/models/book/book.dart';
import 'package:authors_toolbox/services/book_hub/book_manager.dart';

void showBookPopup(BuildContext context, Book book, int index) {
  // Remove the underscore to make it accessible
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBookImage(book),
              const SizedBox(height: 20),
              Text(book.title.isNotEmpty ? book.title : 'Untitled'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _openFile(book.filePath);
                  Navigator.of(context).pop();
                },
                child: const Text('Open'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showEditDialog(context, book, index);
                },
                child: const Text('Edit'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  BookManager.removeBook(
                      index, []); // Call removeBook with updated list
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildBookImage(Book book) {
  return book.imageUrl.isNotEmpty
      ? Image.file(File(book.imageUrl), height: 150)
      : const Icon(Icons.book, size: 150);
}

void _openFile(String filePath) {
  // Logic to open file based on platform
}

void _showEditDialog(BuildContext context, Book book, int index) {
  // Show the edit dialog with fields for title, series, etc.
}
