import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:authors_toolbox/models/book.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class BookHubScreen extends StatefulWidget {
  const BookHubScreen({super.key});

  @override
  _BookHubScreenState createState() => _BookHubScreenState();
}

class _BookHubScreenState extends State<BookHubScreen> {
  //////////////////////////
  /////Global Variables/////
  //////////////////////////
  List<Book> books = [];
  List<String> seriesList = ["Show All"]; // Default to "Show All"
  String selectedSeries = "Show All"; // Default to show all books

  Map<int, String> selectedSeriesMap = {}; // Tracks the series for each book

  // Controllers for book title, file path, and URL
  final List<TextEditingController> _titleControllers = [];
  final List<TextEditingController> _fileControllers = [];
  final List<TextEditingController> _urlControllers = [];

  double _itemWidth = 225; // Initial width for each card

  ////////////////////////
  /////Initial Setup//////
  ////////////////////////
  @override
  void initState() {
    super.initState();
    _loadSeriesFromFile().then((_) {
      _loadBooksFromFile(); // Load books after the series list is loaded
    });
  }

  ////////////////////////////////////
  /////Dispose Unused Controllers/////
  ////////////////////////////////////
  @override
  void dispose() {
    for (var controller in _titleControllers) {
      controller.dispose();
    }
    for (var controller in _fileControllers) {
      controller.dispose();
    }
    for (var controller in _urlControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  ////////////////////////////////////////
  /////Remove Series from Edit Dialog/////
  ////////////////////////////////////////
  void _removeSeriesFromEdit(Book book) {
    if (book.series != 'None' && seriesList.contains(book.series)) {
      setState(() {
        for (var b in books) {
          if (b.series == book.series) {
            b.series = 'None'; // Reset the series for any books in this group
          }
        }

        // Remove the series from the list
        seriesList.remove(book.series);

        // Update the map to reset any books using the removed series
        selectedSeriesMap.updateAll((key, value) {
          return value == book.series ? 'None' : value;
        });

        book.series = 'None'; // Reset the current book's series
        _saveBooksToFile(); // Save the changes
        _saveSeriesToFile(); // Save the changes to series list
      });
    }
  }

  /////////////////////////
  // Get Series File Path//
  /////////////////////////
  Future<String> _getSeriesFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/series.json';
  }

  ////////////////////////////////////
  /////Initialize Text Controllers////
  ////////////////////////////////////
  void _initializeControllers() {
    _titleControllers.clear();
    _fileControllers.clear();
    _urlControllers.clear();
    selectedSeriesMap.clear(); // Clear the map to avoid old data

    for (var i = 0; i < books.length; i++) {
      _titleControllers.add(TextEditingController(text: books[i].title));
      _fileControllers.add(TextEditingController(text: books[i].filePath));
      _urlControllers.add(TextEditingController(text: books[i].url));

      // Ensure the book's series is valid, fallback to 'None' if not
      if (!seriesList.contains(books[i].series) ||
          books[i].series == 'Show All') {
        books[i].series = 'None';
      }

      // Initialize the selectedSeriesMap with each book's current series
      selectedSeriesMap[i] = books[i].series;
    }
  }

  ///////////////////////////////
  /////Build Main UI Scaffold////
  ///////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Book Hub'),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _importBooks, // Import books function
                  icon: const Icon(Icons.import_export),
                  label: const Text('Import'),
                ),
                const SizedBox(width: 20),
                /////////////////////////////
                /////Series/Groups Dropdown//
                /////////////////////////////
                Row(
                  children: [
                    DropdownButton<String>(
                      value:
                          selectedSeries, // This is the filter value for showing books by series
                      items: [
                        'Show All', // Default filter option
                        ...seriesList.where((s) =>
                            s != 'None' &&
                            s !=
                                'Show All'), // Exclude 'None' and avoid duplicating 'Show All'
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          if (seriesList.contains(newValue)) {
                            selectedSeries = newValue!;
                          } else {
                            selectedSeries =
                                'Show All'; // Fallback to a safe value
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 5),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addSeries, // Add a new series
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _removeSeries, // Remove selected series
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                const Text('Card Size:'),
                SizedBox(
                  width: 150, // Limit the slider width
                  child: Slider(
                    value: _itemWidth,
                    min: 150,
                    max: 400, // Slider range to control card size
                    onChanged: (value) {
                      setState(() {
                        _itemWidth = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: const AppNavigationDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = (constraints.maxWidth / _itemWidth).floor();

            return GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount, // Number of items per row
                crossAxisSpacing: 10, // Space between cards horizontally
                mainAxisSpacing: 10, // Space between cards vertically
                childAspectRatio: 0.63, // Adjust aspect ratio for wider cards
              ),
              // Filter books based on the selected series
              itemCount: books.where(_filterBooksBySeries).length + 1,
              itemBuilder: (context, index) {
                final filteredBooks =
                    books.where(_filterBooksBySeries).toList();
                if (index == filteredBooks.length) {
                  return buildAddBookButton(); // "Add Book" button
                } else {
                  return buildBookCard(
                      filteredBooks[index], index); // Build book card
                }
              },
            );
          },
        ),
      ),
    );
  }

  ///////////////////////////
  /////Build Book Card///////
  ///////////////////////////
  Widget buildBookCard(Book book, int index) {
    return InkWell(
      onTap: () {
        // Define what happens when the card is clicked.
        // For example, navigate to a book details page or open an edit dialog.
        _showEditDialog(index);
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
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(-6, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              ///////////////////////////
              /////Book Cover Image//////
              ///////////////////////////
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: book.imageUrl.isNotEmpty
                          ? FileImage(File(book.imageUrl)) as ImageProvider
                          : const AssetImage('assets/placeholder.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              ///////////////////////////
              /////Series Tag on Top/////
              ///////////////////////////
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: Text(
                    book.series != 'None'
                        ? book.series
                        : '', // Show series name if available
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              /////////////////////////
              /////Fade Overlay////////
              /////////////////////////
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),
              /////////////////////////////
              /////Dropdown for Actions////
              /////////////////////////////
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (String result) {
                      if (result == 'edit') {
                        _showEditDialog(index);
                      } else if (result == 'delete') {
                        _removeBook(index);
                      } else if (result == 'file') {
                        _openFile(book.filePath, index);
                      } else if (result == 'url') {
                        _launchUrl(book.url);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                      const PopupMenuItem(value: 'file', child: Text('Open')),
                      const PopupMenuItem(value: 'url', child: Text('URL')),
                    ],
                  ),
                ),
              ),
              ///////////////////////////
              /////Centered Title////////
              ///////////////////////////
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
                    child: Column(
                      children: [
                        Text(
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
                      ],
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

  //////////////////////////////////
  /////Build "Add Book" Button//////
  //////////////////////////////////
  Widget buildAddBookButton() {
    return GestureDetector(
      onTap: _addNewBook, // Add a new book
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.blue[100],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(6, 6),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, size: 80, color: Colors.blue),
              SizedBox(height: 10),
              Text('Add Book', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  /////////////////////////////////////
  /////Helper Method: Pick a File//////
  /////////////////////////////////////
  Future<String?> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      return result.files.single.path!;
    }
    return null;
  }

  ////////////////////////////////////////////
  /////Helper Method: Add a New Book//////////
  ////////////////////////////////////////////
  void _addNewBook() {
    setState(() {
      books.add(Book(title: '', filePath: '', url: '', series: 'None'));
      _initializeControllers();
    });

    _showEditDialog(books.length - 1);
  }

  /////////////////////////////////////////
  /////Helper Method: Show Edit Dialog/////
  /////////////////////////////////////////
  void _showEditDialog(int index) async {
    TextEditingController imageController =
        TextEditingController(text: books[index].imageUrl);

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Book Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title input field
                TextField(
                  controller: _titleControllers[index],
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 10),
                ////////////////////////////////
                // Image picker for book cover//
                ////////////////////////////////
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: imageController,
                        decoration:
                            const InputDecoration(labelText: 'Image URL'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: () async {
                        final pickedFile = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            imageController.text = pickedFile.path;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                //////////////////////////////
                // File picker for file path//
                //////////////////////////////
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fileControllers[index],
                        decoration:
                            const InputDecoration(labelText: 'File Path'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: () async {
                        final pickedFile = await _pickFile();
                        if (pickedFile != null) {
                          setState(() {
                            _fileControllers[index].text = pickedFile;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ////////////////////
                // URL input field//
                ////////////////////
                TextField(
                  controller: _urlControllers[index],
                  decoration: const InputDecoration(labelText: 'URL'),
                ),
                const SizedBox(height: 10),
                /////////////////////////////////////////////
                // Dropdown for selecting the book's series//
                /////////////////////////////////////////////
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: books[index].series.isNotEmpty &&
                                seriesList.contains(books[index].series)
                            ? books[index].series
                            : 'None', // Fallback to 'None' if the series is invalid or empty
                        items: [
                          'None', // Default option for books without a series
                          ...seriesList.where((s) =>
                              s !=
                              'Show All') // Exclude "Show All" from series options
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            books[index].series =
                                newValue ?? 'None'; // Update the series value
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Add Series Button
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addSeries, // Add a new series
                    ),
                    // Remove Series Button
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => _removeSeriesFromEdit(books[index]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(); // Close the dialog without saving
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  books[index].title = _titleControllers[index].text;
                  books[index].filePath = _fileControllers[index].text;
                  books[index].url = _urlControllers[index].text;
                  books[index].imageUrl = imageController.text;
                  _saveBooksToFile(); // Save changes to file
                });
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /////////////////////////////////////
  /////Helper Method: Pick Image///////
  /////////////////////////////////////
  Future<void> pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        books[index].imageUrl = pickedFile.path;
        _saveBooksToFile();
      });
    }
  }

  /////////////////////////////////////
  /////Helper Method: Remove Book//////
  /////////////////////////////////////
  void _removeBook(int index) {
    setState(() {
      books.removeAt(index);
      _initializeControllers();
      _saveBooksToFile();
    });
  }

  /////////////////////////////////////
  /////Helper Method: Open File////////
  /////////////////////////////////////
  void _openFile(String filePath, int index) async {
    if (filePath.isEmpty) return;

    if (Platform.isWindows) {
      await Process.run('explorer', [filePath]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [filePath]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [filePath]);
    }
  }

  /////////////////////////////////////
  /////Helper Method: Launch URL///////
  /////////////////////////////////////
  void _launchUrl(String url) async {
    if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (kDebugMode) {
        print("Invalid or empty URL");
      }
    }
  }

  /////////////////////////////////////
  /////Helper Method: Import Books/////
  /////////////////////////////////////
  void _importBooks() async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) return;

    final dir = Directory(directoryPath);
    final List<FileSystemEntity> files = dir.listSync();
    final supportedExtensions = ['doc', 'docx', 'pdf', 'scrivx'];

    setState(() {
      for (var file in files) {
        String ext = p.extension(file.path).replaceAll('.', '');
        if (supportedExtensions.contains(ext)) {
          books.add(
            Book(
              title: p.basenameWithoutExtension(file.path),
              filePath: file.path,
              url: '',
              series: 'None',
            ),
          );
        }
      }
      _initializeControllers();
      _saveBooksToFile();
    });
  }

  ///////////////////////////////////
  // Save the series list to a file//
  ///////////////////////////////////
  Future<void> _saveSeriesToFile() async {
    String path = await _getSeriesFilePath();
    File file = File(path);
    String jsonString = jsonEncode(seriesList);
    await file.writeAsString(jsonString);
  }

  /////////////////////////////////////
  // Load the series list from a file//
  /////////////////////////////////////
  Future<void> _loadSeriesFromFile() async {
    String path = await _getSeriesFilePath();
    File file = File(path);

    if (await file.exists()) {
      String jsonString = await file.readAsString();
      List<dynamic> loadedSeriesList = jsonDecode(jsonString);

      setState(() {
        seriesList = loadedSeriesList.cast<String>()..insert(0, "Show All");
      });
      if (kDebugMode) {
        print('Series list loaded: $seriesList');
      } // Debugging log
    } else {
      if (kDebugMode) {
        print('Series file does not exist.');
      } // Debugging log
    }
  }

  //////////////////////////////////////
  /////Helper Method: Save to JSON//////
  //////////////////////////////////////
  Future<void> _saveBooksToFile() async {
    String path = await _getFilePath();
    File file = File(path);

    List<Map<String, dynamic>> booksJson =
        books.map((book) => book.toJson()).toList();

    String jsonString = jsonEncode(booksJson);
    await file.writeAsString(jsonString);
  }

  //////////////////////////////////////
  /////Helper Method: Load from JSON////
  //////////////////////////////////////
  Future<void> _loadBooksFromFile() async {
    String path = await _getFilePath();
    File file = File(path);

    if (await file.exists()) {
      String jsonString = await file.readAsString();
      List<dynamic> booksJson = jsonDecode(jsonString);

      setState(() {
        books = booksJson.map((bookJson) {
          Book book = Book.fromJson(bookJson);

          // Ensure the book series is valid, fallback to 'None' if invalid
          if (!seriesList.contains(book.series)) {
            book.series = 'None';
          }

          return book;
        }).toList();

        // Initialize controllers with the loaded books
        _initializeControllers();
      });
    }
  }

  /////////////////////////////////////
  /////Helper Method: Get File Path////
  /////////////////////////////////////
  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/books.json';
  }

  ////////////////////////////////////////////
  /////Helper Method: Filter Books by Series//
  ////////////////////////////////////////////
  bool _filterBooksBySeries(Book book) {
    if (selectedSeries == "Show All") {
      return true; // Show all books
    } else {
      return book.series == selectedSeries; // Filter by selected series
    }
  }

  ////////////////////////////////////////////
  /////Helper Method: Add a New Series////////
  ////////////////////////////////////////////
  void _addSeries() {
    TextEditingController seriesNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Series'),
          content: TextField(
            controller: seriesNameController,
            decoration: const InputDecoration(labelText: 'Series Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(); // Close dialog without action
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String newSeries = seriesNameController.text.trim();

                // Ensure that the new series doesn't already exist and is valid
                if (newSeries.isNotEmpty &&
                    !seriesList.contains(newSeries) &&
                    newSeries != 'Show All') {
                  setState(() {
                    seriesList.add(newSeries); // Add new series to the list
                    _saveSeriesToFile(); // Save the updated series list
                  });
                }

                Navigator.of(dialogContext).pop(); // Close dialog after adding
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  ////////////////////////////////////////////
  /////Helper Method: Remove a Series/////////
  ////////////////////////////////////////////
  void _removeSeries() {
    if (selectedSeries != "Show All") {
      setState(() {
        for (var book in books) {
          if (book.series == selectedSeries) {
            book.series = 'None'; // Reset the series of books in this group
          }
        }
        seriesList.remove(selectedSeries);
        selectedSeries = 'Show All'; // Ensure selectedSeries is valid
        _saveBooksToFile(); // Save changes to books
        _saveSeriesToFile(); // Save changes to series
      });
    }
  }
}
