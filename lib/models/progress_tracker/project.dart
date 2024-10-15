import 'package:authors_toolbox/models/progress_tracker/word_count_entry.dart';

///////////////
// Project model to store project details and word count progress entries
///////////////
class Project {
  String name;
  String description;
  int wordCountGoal;
  int currentWordCount;
  List<WordCountEntry> wordCountEntries;

  Project({
    required this.name,
    required this.description,
    required this.wordCountGoal,
    this.currentWordCount = 0,
    required this.wordCountEntries,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'wordCountGoal': wordCountGoal,
        'currentWordCount': currentWordCount,
        'wordCountEntries':
            wordCountEntries.map((entry) => entry.toJson()).toList(),
      };

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['name'],
      description: json['description'],
      wordCountGoal: json['wordCountGoal'],
      currentWordCount: json['currentWordCount'],
      wordCountEntries: (json['wordCountEntries'] as List)
          .map((data) => WordCountEntry.fromJson(data))
          .toList(),
    );
  }
}
