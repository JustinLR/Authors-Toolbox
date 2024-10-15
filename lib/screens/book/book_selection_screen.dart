import 'package:authors_toolbox/models/book/book.dart';
import 'package:flutter/material.dart';

class BookSelectionScreen extends StatefulWidget {
  final List<Book> books;
  final String selectedSeries;
  final Future<void> Function() saveBooks;

  BookSelectionScreen({
    required this.books,
    required this.selectedSeries,
    required this.saveBooks,
  });

  @override
  _BookSelectionScreenState createState() => _BookSelectionScreenState();
}

class _BookSelectionScreenState extends State<BookSelectionScreen> {
  List<Book> selectedBooks = [];
  int? hoveredIndex; // To track the index of the hovered item

  @override
  void initState() {
    super.initState();
    // Preselect books that are already in the selected series, and exclude "Show All"
    selectedBooks = widget.books
        .where((book) =>
            book.series == widget.selectedSeries && book.series != 'Show All')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Books to ${widget.selectedSeries}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed:
                _assignBooksToSeries, // Call save without navigating back
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.books.length,
        itemBuilder: (context, index) {
          Book book = widget.books[index];
          // Exclude "Show All" from the series check
          bool isSelected =
              selectedBooks.contains(book) && book.series != 'Show All';
          bool isHovered = hoveredIndex == index ||
              isSelected; // Keep hover effect for selected books

          return MouseRegion(
            onEnter: (_) =>
                setState(() => hoveredIndex = index), // Set hovered index
            onExit: (_) => setState(() =>
                hoveredIndex = null), // Reset hovered index if not selected
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedBooks.remove(book); // Deselect the book
                  } else {
                    selectedBooks.add(book); // Select the book
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.3) // Highlight selected item
                      : isHovered
                          ? Colors.blue.withOpacity(0.1) // Light hover effect
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(book.title),
                  subtitle: Text(book.series.isEmpty || book.series == 'None'
                      ? 'No series'
                      : 'In series: ${book.series}'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _assignBooksToSeries() {
    setState(() {
      // Assign the selected series to the selected books
      for (var book in selectedBooks) {
        if (book.series != 'Show All') {
          book.series = widget.selectedSeries; // Assign the selected series
        }
      }

      // Remove the series from any books that were previously in the series but are now deselected
      for (var book in widget.books) {
        if (!selectedBooks.contains(book) &&
            book.series == widget.selectedSeries) {
          book.series = 'None'; // Remove from series
        }
      }

      widget.saveBooks(); // Save the updated books

      // Show a Snackbar to confirm the save
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Books saved successfully!'),
        ),
      );
    });
  }
}
