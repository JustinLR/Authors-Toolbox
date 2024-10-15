///////////////
// WordCountEntry to record word count added and timestamp
///////////////
class WordCountEntry {
  int wordsAdded;
  DateTime dateTime;

  WordCountEntry({required this.wordsAdded, required this.dateTime});

  Map<String, dynamic> toJson() => {
        'wordsAdded': wordsAdded,
        'dateTime': dateTime.toIso8601String(),
      };

  factory WordCountEntry.fromJson(Map<String, dynamic> json) {
    return WordCountEntry(
      wordsAdded: json['wordsAdded'],
      dateTime: DateTime.parse(json['dateTime']),
    );
  }
}
