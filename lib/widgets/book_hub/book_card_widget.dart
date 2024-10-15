import 'dart:io';

import 'package:flutter/material.dart';
import 'package:authors_toolbox/models/book/book.dart';
import 'package:authors_toolbox/widgets/book_hub/book_popup.dart'; // Ensure this is used

class BookCardWidget extends StatelessWidget {
  final Book book;
  final int index;

  const BookCardWidget({Key? key, required this.book, required this.index})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Correctly call the _showBookPopup function from book_popup.dart
        showBookPopup(context, book,
            index); // Change _showBookPopup to showBookPopup (remove the underscore if it's a top-level function)
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 3,
              offset: const Offset(6, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: book.coverImagePath!.isNotEmpty
                          ? FileImage(File(book.coverImagePath!))
                              as ImageProvider
                          : const AssetImage('assets/placeholder.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      book.title.isNotEmpty ? book.title : 'Untitled',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
