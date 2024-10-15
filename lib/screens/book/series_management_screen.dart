import 'package:flutter/material.dart';
import 'series_manager.dart';
import 'book_selection_screen.dart'; // Import the BookSelectionScreen
import 'package:authors_toolbox/models/book/book.dart';

class SeriesManagementScreen extends StatefulWidget {
  final List<Book> books;
  final List<String> seriesList;
  final Future<void> Function() saveBooks;
  final Future<void> Function() saveSeries;
  final SeriesManager seriesManager;

  SeriesManagementScreen({
    required this.books,
    required this.seriesList,
    required this.saveBooks,
    required this.saveSeries,
    required this.seriesManager,
  });

  @override
  _SeriesManagementScreenState createState() => _SeriesManagementScreenState();
}

class _SeriesManagementScreenState extends State<SeriesManagementScreen> {
  @override
  Widget build(BuildContext context) {
    // Filter out "Show All" from the series list before displaying
    List<String> filteredSeriesList = widget.seriesManager.seriesList
        .where((series) => series != 'Show All')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Series'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop({
              'selectedSeries': 'Show All',
              'seriesList': widget.seriesManager.seriesList,
              'books': widget.books,
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addSeriesDialog(),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: filteredSeriesList.length,
        itemBuilder: (context, index) {
          String seriesName = filteredSeriesList[index];
          return ListTile(
            title: Text(seriesName),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _assignBooksToSeries(seriesName),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      widget.seriesManager
                          .removeSeries(seriesName, widget.books);
                    });
                    widget.saveSeries(); // Save the updated series list
                    widget.saveBooks(); // Save updated books
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Open BookSelectionScreen to assign books to a series
  void _assignBooksToSeries(String seriesName) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => BookSelectionScreen(
          books: widget.books,
          selectedSeries: seriesName,
          saveBooks: widget.saveBooks,
        ),
      ),
    )
        .then((_) {
      setState(() {
        widget.saveSeries(); // Save the series after assigning books
        widget.saveBooks(); // Save books after assigning books to a series
      });
    });
  }

  void _addSeriesDialog() {
    TextEditingController seriesNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Series'),
          content: TextField(
            controller: seriesNameController,
            decoration: const InputDecoration(labelText: 'Series Name'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  widget.seriesManager.addSeries(seriesNameController.text);
                });
                widget.saveSeries(); // Save the updated series list
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
