import 'package:authors_toolbox/screens/book/series_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:authors_toolbox/models/book/book.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:collection/collection.dart';
import 'series_manager.dart';

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
  SeriesManager seriesManager = SeriesManager();
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
    // Load series from file and assign to seriesManager
    seriesManager.loadSeriesFromFile().then((_) {
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

  void _showBookPopup(Book book, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book cover on the left
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: double
                            .infinity, // Make the image span the full height of the window
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: book.coverImagePath!.isNotEmpty
                                ? FileImage(File(book.coverImagePath!))
                                    as ImageProvider
                                : const AssetImage('assets/placeholder.png'),
                            fit: BoxFit
                                .fitHeight, // Scale the image to fit the full height
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                        width: 20), // Space between image and content

                    // Description and buttons on the right
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Add some space above the description
                          const SizedBox(
                              height:
                                  20), // Adds space between the top and the description

                          // Book description
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                book.description?.isNotEmpty == true
                                    ? book.description!
                                    : 'No description available.',
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Centering the Open and Edit buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Open button
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the popup
                                  _openFile(
                                      book.filePath, index); // Open the file
                                },
                                child: const Text('Open'),
                              ),
                              const SizedBox(width: 10),
                              // Edit button
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the popup
                                  _showEditDialog(
                                      index); // Open the edit dialog
                                },
                                child: const Text('Edit'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Delete button at the top right
              Positioned(
                top: 8,
                right: 8,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Set the button color to red
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the popup first
                    _showDeleteConfirmationDialog(
                        book, index); // Show confirmation dialog
                  },
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(Book book, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text(
              'Are you sure you want to delete this book? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red, // Set the confirm button color to red
              ),
              onPressed: () {
                // Remove the book from the list and close both dialogs
                setState(() {
                  books.removeAt(index);
                });
                Navigator.of(context).pop(); // Close the confirmation dialog
                _saveBooksToFile(); // Save changes after deletion
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

////////////////////////////////////
/////Initialize Text Controllers////
////////////////////////////////////
  void _initializeControllers() {
    _titleControllers.clear();
    _fileControllers.clear();
    _urlControllers.clear();
    selectedSeriesMap.clear(); // Ensure the map is cleared

    for (var i = 0; i < books.length; i++) {
      _titleControllers.add(TextEditingController(text: books[i].title));
      _fileControllers.add(TextEditingController(text: books[i].filePath));
      _urlControllers.add(TextEditingController(text: books[i].url));

      if (!seriesManager.seriesList.contains(books[i].series) ||
          books[i].series == 'Show All') {
        books[i].series = 'None';
      }

      selectedSeriesMap[i] = books[i].series;
    }
  }

  // Helper method to sort books
  void _sortBooks() {
    setState(() {
      if (_selectedSortOption == 'Title') {
        books.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      } else if (_selectedSortOption == 'File Path') {
        books.sort((a, b) =>
            a.filePath.toLowerCase().compareTo(b.filePath.toLowerCase()));
      } else if (_selectedSortOption == 'Series') {
        books.sort(
            (a, b) => a.series.toLowerCase().compareTo(b.series.toLowerCase()));
      }
    });
  }

  // Sorting criteria options
  String _selectedSortOption = 'Title'; // Default sort by title

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
                // Import button for importing books
                ElevatedButton.icon(
                  onPressed: _importBooksWithSeriesAssignment,
                  icon: const Icon(Icons.import_export),
                  label: const Text('Import'),
                ),
                const SizedBox(width: 20),

                // Sorting Dropdown
                DropdownButton<String>(
                  value: _selectedSortOption,
                  items: ['Title', 'File Path', 'Series'].map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSortOption = newValue!;
                      _sortBooks(); // Sort books based on selected option
                    });
                  },
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
                        ...seriesManager.seriesList.where((s) =>
                            s != 'None' &&
                            s != 'Show All'), // Exclude 'None' and 'Show All'
                        'Manage Series...', // Add 'Manage Series' option at the end
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue == 'Manage Series...') {
                          Navigator.of(context)
                              .push(
                            MaterialPageRoute(
                              builder: (context) => SeriesManagementScreen(
                                books: books, // Pass the current books
                                seriesList: seriesManager.seriesList,
                                saveBooks: _saveBooksToFile,
                                saveSeries: seriesManager.saveSeriesToFile,
                                seriesManager: seriesManager,
                              ),
                            ),
                          )
                              .then((result) {
                            if (result != null &&
                                result is Map<String, dynamic>) {
                              setState(() {
                                // Update the books and series with the returned values
                                seriesManager.seriesList =
                                    result['seriesManager.seriesList'] ??
                                        seriesManager.seriesList;
                                books = result['books'] ?? books;
                              });
                            }
                          });
                        } else {
                          setState(() {
                            selectedSeries = newValue ??
                                'Show All'; // Update the selected series
                          });
                        }
                      },
                    ),
                    //const SizedBox(width: 5),
                    //IconButton(
                    //  icon: const Icon(Icons.add),
                    //  onPressed: _addSeries, // Add a new series
                    //),
                    //IconButton(
                    //  icon: const Icon(Icons.remove),
                    //  onPressed: _removeSeries, // Remove selected series
                    //),
                  ],
                ),
                const SizedBox(width: 20),

                // Card size slider
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
        _showBookPopup(book, index);
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
              // Display book cover or placeholder
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
              // Display book title
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
              // IconButton to select a cover image
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.image, color: Colors.white),
                  onPressed: () async {
                    String? coverPath = await _pickCoverImage();
                    if (coverPath != null) {
                      _updateBookCover(book.filePath, coverPath);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _pickCoverImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image, // Restrict the picker to images only
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path; // Return the selected image path
    }
    return null;
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
      books.add(Book(
          title: '',
          filePath: '',
          url: '',
          series: 'None',
          coverImagePath: ''));
      _initializeControllers(); // Ensure controllers are initialized after adding a new book
    });

    _showEditDialog(
        books.length - 1); // Show the dialog for the newly added book
  }

  /////////////////////////////////////////
  /////Helper Method: Show Edit Dialog/////
  /////////////////////////////////////////
  void _showEditDialog(int index) async {
    TextEditingController imageController =
        TextEditingController(text: books[index].coverImagePath);
    TextEditingController descriptionController =
        TextEditingController(text: books[index].description ?? '');

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

                // Image picker for book cover
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

                // File picker for file path
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

                // Dropdown for selecting the book's series
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: books[index].series.isNotEmpty &&
                                seriesManager.seriesList
                                    .contains(books[index].series)
                            ? books[index].series
                            : 'None', // Fallback to 'None' if the series is invalid or empty
                        items: [
                          'None', // Default option for books without a series
                          ...seriesManager.seriesList.where((s) =>
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
                    //IconButton(
                    //  icon: const Icon(Icons.add),
                    //  onPressed: _addSeries, // Add a new series
                    //),
                    // Remove Series Button
                    //IconButton(
                    //  icon: const Icon(Icons.remove),
                    //  onPressed: () => _removeSeriesFromEdit(books[index]),
                    //),
                  ],
                ),
                const SizedBox(height: 10),

                // Description input field (moved to the bottom)
                TextField(
                  controller:
                      descriptionController, // Directly tied to the description
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3, // Allow multiple lines
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
                  books[index].coverImagePath = imageController.text;
                  books[index].description =
                      descriptionController.text; // Save the description
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
        books[index].coverImagePath = pickedFile.path;
        _saveBooksToFile();
      });
    }
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
  /////Helper Method: Import Books/////
  /////////////////////////////////////
  void _importBooksWithSeriesAssignment() async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath();

    if (directoryPath == null) {
      print("No directory selected.");
      return;
    }
    print("Directory selected: $directoryPath");

    final dir = Directory(directoryPath);
    final List<FileSystemEntity> files = [];

    // Recursively list all files up to 3 levels deep
    await for (var entity in _listFilesWithDepth(dir, 0)) {
      if (entity is File) {
        files.add(entity); // Add valid files to the list
      }
    }

    setState(() {
      // Remove duplicates by using a Set based on file paths
      final Map<String, Book> uniqueBooks =
          {}; // Keyed by filePath for uniqueness
      for (var book in books) {
        uniqueBooks[book.filePath] = book;
      }

      // Clear the current books list and add only the unique books
      books.clear();
      books.addAll(uniqueBooks.values);
      print(
          "Removed duplicates, books list now contains ${books.length} unique books.");

      // Import new books, without adding duplicates
      final supportedExtensions = [
        'doc',
        'docx',
        'pdf',
        'scrivx'
      ]; // Main book extensions

      for (var file in files) {
        String ext = p.extension(file.path).replaceAll('.', '');

        if (supportedExtensions.contains(ext)) {
          Book? existingBook =
              books.firstWhereOrNull((book) => book.filePath == file.path);

          if (existingBook != null) {
            print(
                "Book already exists: ${existingBook.title}, preserving cover.");
          } else {
            Book newBook = Book(
              title: p.basenameWithoutExtension(file.path),
              filePath: file.path,
              url: '',
              coverImagePath: '',
              series: 'None', // No automatic series assignment
            );
            books.add(newBook);
          }
        } else {}
      }

      _initializeControllers();
      _saveBooksToFile();
    });
  }

// Helper function to get the parent folder of a file (
  void _updateBookCover(String filePath, String newCoverPath) {
    setState(() {
      // Find the book by file path (which should be unique)
      Book? bookToUpdate =
          books.firstWhereOrNull((book) => book.filePath == filePath);

      if (bookToUpdate != null) {
        // Update the book's cover (assuming there's a field for cover)
        bookToUpdate.coverImagePath = newCoverPath;

        print(
            "Updated cover for book: ${bookToUpdate.title}, FilePath: ${bookToUpdate.filePath}, New Cover Path: $newCoverPath");

        // Save the updated books list to file (optional)
        _saveBooksToFile();
      } else {
        print("No book found with file path: $filePath");
      }
    });
  }

// Helper function to recursively list files up to a specified depth (3 levels deep in this case)
  Stream<FileSystemEntity> _listFilesWithDepth(
      Directory dir, int depth) async* {
    if (depth > 3) return; // Stop recursion after 3 levels deep

    await for (var entity in dir.list(followLinks: false)) {
      if (entity is Directory) {
        yield* _listFilesWithDepth(
            entity, depth + 1); // Recurse into subdirectories
      } else if (entity is File) {
        yield entity; // Return the file
      }
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
          if (!seriesManager.seriesList.contains(book.series)) {
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
      return book.series == selectedSeries; // Filter by the selected series
    }
  }
}
