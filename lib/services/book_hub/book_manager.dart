import 'dart:convert';
import 'dart:io';
import 'package:authors_toolbox/models/book/book.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class BookManager {
  static List<String> seriesList = ["Show All"];

  static Future<void> loadSeriesFromFile() async {
    String path = await _getSeriesFilePath();
    File file = File(path);
    if (await file.exists()) {
      String jsonString = await file.readAsString();
      seriesList = (jsonDecode(jsonString) as List<dynamic>).cast<String>();
    }
  }

  static Future<List<Book>> loadBooksFromFile() async {
    String path = await _getFilePath();
    File file = File(path);
    if (await file.exists()) {
      String jsonString = await file.readAsString();
      return (jsonDecode(jsonString) as List<dynamic>)
          .map((bookJson) => Book.fromJson(bookJson))
          .toList();
    }
    return [];
  }

  static Future<void> saveBooksToFile(List<Book> books) async {
    String path = await _getFilePath();
    File file = File(path);
    String jsonString = jsonEncode(books.map((book) => book.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  static Future<void> removeBook(int index, List<Book> books) async {
    books.removeAt(index);
    await saveBooksToFile(books);
  }

  static Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/books.json';
  }

  static Future<String> _getSeriesFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/series.json';
  }

  // File Picker for book import
  static Future<String?> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      return result.files.single.path!;
    }
    return null;
  }
}
