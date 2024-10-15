import 'dart:convert';
import 'dart:io';
import 'package:authors_toolbox/models/book/book.dart';
import 'package:path_provider/path_provider.dart';

class SeriesManager {
  List<String> seriesList = ["Show All"];

  /////////////////////////
  // Get Series File Path//
  /////////////////////////
  Future<String> _getSeriesFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    String path = '${directory.path}/series.json';
    print('Series file path: $path');
    return path;
  }

  ////////////////////////////////////////////
  ///// Add a New Series in SeriesManager /////
  ////////////////////////////////////////////
  void addSeries(String newSeries) {
    if (newSeries.isNotEmpty &&
        !seriesList.contains(newSeries) &&
        newSeries != 'Show All') {
      seriesList.add(newSeries);
      saveSeriesToFile(); // Save the updated series list
    }
  }

  ////////////////////////////////////////////
  ///// Remove a Series in SeriesManager /////
  ////////////////////////////////////////////
  void removeSeries(String seriesName, List<Book> books) {
    if (seriesList.contains(seriesName) && seriesName != "Show All") {
      seriesList.remove(seriesName);
      for (var book in books) {
        if (book.series == seriesName) {
          book.series = 'None'; // Reset the series of books in this group
        }
      }
      saveSeriesToFile(); // Save the updated series list
    }
  }

  ///////////////////////////////////
  // Save the series list to a file//
  ///////////////////////////////////
  Future<void> saveSeriesToFile() async {
    String path = await _getSeriesFilePath();
    File file = File(path);
    String jsonString = jsonEncode(seriesList);
    await file.writeAsString(jsonString);
    print('Saved series list to $path: $jsonString');
  }

  // Load the series list from a file (if needed in SeriesManager)
  Future<void> loadSeriesFromFile() async {
    String path = await _getSeriesFilePath();
    File file = File(path);

    if (await file.exists()) {
      String jsonString = await file.readAsString();
      List<dynamic> loadedSeriesList = jsonDecode(jsonString);

      seriesList = loadedSeriesList.cast<String>().toSet().toList();
      if (!seriesList.contains("Show All")) {
        seriesList.insert(0, "Show All");
      }
      print('Series list loaded: $seriesList');
    } else {
      print('Series file does not exist.');
    }
  }
}
