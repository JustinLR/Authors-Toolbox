import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart for graphs
import 'package:intl/intl.dart'; // For date formatting
import 'package:flutter/services.dart'; // Required for TextInputFormatter

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

class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String oldText = oldValue.text;
    String newText = newValue.text;

    // Remove non-numeric characters from the input
    String digitsOnly = newText.replaceAll(RegExp(r'[^0-9]'), '');

    // We maintain the fixed format: HH:MM:SS
    String formattedTime = oldText;

    // Calculate the cursor position before formatting
    int cursorPosition = newValue.selection.start;

    // Limit input to a maximum of 6 digits (HHMMSS)
    if (digitsOnly.length > 6) {
      digitsOnly = digitsOnly.substring(0, 6);
    }

    // Handle formatting by replacing the numeric placeholders in the existing formatted time
    int digitIndex = 0;
    for (int i = 0; i < formattedTime.length; i++) {
      if (digitIndex < digitsOnly.length && i != 2 && i != 5) {
        formattedTime =
            formattedTime.replaceRange(i, i + 1, digitsOnly[digitIndex]);
        digitIndex++;
      }
    }

    // Adjust the cursor position to ensure it doesn't land on colons
    if (cursorPosition == 2 || cursorPosition == 5) {
      cursorPosition++;
    }

    // Ensure the cursor position stays within the formatted time
    cursorPosition = cursorPosition.clamp(0, formattedTime.length);

    return TextEditingValue(
      text: formattedTime,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

///////////////
// Stopwatch Widget to handle the timer and alarm functionality
///////////////
class StopwatchWidget extends StatefulWidget {
  const StopwatchWidget({super.key});

  @override
  _StopwatchWidgetState createState() => _StopwatchWidgetState();
}

class _StopwatchWidgetState extends State<StopwatchWidget> {
  late Timer _timer;
  int _seconds = 0;
  bool _isRunning = false;
  int? _alarmSeconds;
  int _maxSeconds = 24 * 3600; // 24 hours in seconds
  Color _progressColor = Colors.blueAccent;

  final TextEditingController _alarmController =
      TextEditingController(text: "00:00:00");

  // Convert formatted string (HH:MM:SS) to total seconds
  int _parseTimeToSeconds(String time) {
    final parts = time.split(':');
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;
    return (hours * 3600) + (minutes * 60) + seconds;
  }

  // Convert total seconds to formatted string (HH:MM:SS)
  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  // Start the stopwatch
  void _startStopwatch() {
    final alarmValue = _parseTimeToSeconds(_alarmController.text);
    if (alarmValue > 0) {
      _setAlarm(alarmValue);
    }

    if (!_isRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;

          if (_alarmSeconds != null && _seconds >= _alarmSeconds!) {
            _stopStopwatch();
            _progressColor = Colors.red;
            _showAlarmDialog();
          }

          if (_seconds >= _maxSeconds) {
            _stopStopwatch();
          }
        });
      });

      setState(() {
        _isRunning = true;
      });
    }
  }

  // Stop the stopwatch
  void _stopStopwatch() {
    if (_isRunning && _timer.isActive) {
      _timer.cancel();
      setState(() {
        _isRunning = false;
      });
    }
  }

  // Reset the stopwatch
  void _resetStopwatch() {
    if (_isRunning && _timer.isActive) {
      _timer.cancel();
    }
    setState(() {
      _seconds = 0;
      _isRunning = false;
      _alarmSeconds = null;
      _progressColor = Colors.blueAccent;
      _alarmController.text = "00:00:00"; // Reset the input field to default
    });
  }

  // Set alarm time in seconds
  void _setAlarm(int seconds) {
    setState(() {
      _alarmSeconds = seconds;
      _progressColor = Colors.blueAccent;
    });
  }

  // Show alarm dialog when time is up
  void _showAlarmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Alarm"),
          content: const Text("Time's up!"),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = _seconds / (_alarmSeconds ?? _maxSeconds);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircularPercentIndicator(
          radius: 100.0,
          lineWidth: 8.0,
          percent: progress.clamp(0.0, 1.0),
          center: Text(
            _formatTime(_seconds),
            style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          progressColor: _progressColor,
          backgroundColor: Colors.grey.shade300,
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _startStopwatch,
              child: const Text("Start"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isRunning ? _stopStopwatch : null,
              child: const Text("Stop"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _resetStopwatch,
              child: const Text("Reset"),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 150,
              child: TextField(
                controller: _alarmController,
                decoration:
                    const InputDecoration(labelText: 'Set Alarm (HH:MM:SS)'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  TimeInputFormatter(), // Apply custom formatter to lock colons and allow numeric input
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

///////////////
// Progress Tracker Screen for managing projects and progress
///////////////
class ProgressTrackerScreen extends StatefulWidget {
  const ProgressTrackerScreen({super.key});

  @override
  _ProgressTrackerScreenState createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends State<ProgressTrackerScreen> {
  List<Project> _projects = [];
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _wordCountGoalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjects(); // Load projects when the screen initializes
  }

  Future<void> _loadProjects() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? projectsJson = prefs.getString('projects');
    if (projectsJson != null) {
      setState(() {
        _projects = (json.decode(projectsJson) as List)
            .map((data) => Project.fromJson(data))
            .toList();
      });
    }
  }

  Future<void> _saveProjects() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String projectsJson =
        json.encode(_projects.map((p) => p.toJson()).toList());
    await prefs.setString('projects', projectsJson);
  }

  void _addProject() {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _wordCountGoalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    final wordCountGoal = int.tryParse(_wordCountGoalController.text);
    if (wordCountGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Word count goal must be a number')),
      );
      return;
    }

    setState(() {
      _projects.add(Project(
        name: _nameController.text,
        description: _descriptionController.text,
        wordCountGoal: wordCountGoal,
        wordCountEntries: [],
      ));

      _nameController.clear();
      _descriptionController.clear();
      _wordCountGoalController.clear();
    });
    _saveProjects(); // Save the updated project list to SharedPreferences
  }

  void _editProject(int index) {
    _nameController.text = _projects[index].name;
    _descriptionController.text = _projects[index].description;
    _wordCountGoalController.text = _projects[index].wordCountGoal.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Project"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: _wordCountGoalController,
                decoration: const InputDecoration(labelText: 'Word Count Goal'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              child: const Text("Save"),
              onPressed: () {
                final wordCountGoal =
                    int.tryParse(_wordCountGoalController.text);
                if (wordCountGoal != null) {
                  setState(() {
                    _projects[index].name = _nameController.text;
                    _projects[index].description = _descriptionController.text;
                    _projects[index].wordCountGoal = wordCountGoal;
                  });
                  _saveProjects(); // Save to SharedPreferences after editing
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Word count goal must be a number')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteProject(int index) {
    setState(() {
      _projects.removeAt(index);
    });
    _saveProjects(); // Save to SharedPreferences after deletion
  }

  void _addWordCount(int index, int wordCount) {
    setState(() {
      _projects[index].currentWordCount += wordCount;
      _projects[index].wordCountEntries.add(
            WordCountEntry(wordsAdded: wordCount, dateTime: DateTime.now()),
          );
    });
    _saveProjects(); // Save the updated project list to SharedPreferences
  }

  void _showAddWordCountDialog(int index) {
    final wordCountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Word Count"),
          content: TextField(
            controller: wordCountController,
            decoration: const InputDecoration(labelText: 'Words Written'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            ElevatedButton(
              child: const Text("Add"),
              onPressed: () {
                final wordCount = int.tryParse(wordCountController.text);
                if (wordCount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid word count')),
                  );
                } else {
                  _addWordCount(index, wordCount);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  double _calculateWeeklyAverage() {
    DateTime now = DateTime.now();
    DateTime oneWeekAgo = now.subtract(const Duration(days: 7));
    int totalWords = 0;
    int entryCount = 0;

    for (var project in _projects) {
      for (var entry in project.wordCountEntries) {
        if (entry.dateTime.isAfter(oneWeekAgo)) {
          totalWords += entry.wordsAdded;
          entryCount++;
        }
      }
    }

    return entryCount > 0 ? totalWords / entryCount : 0;
  }

  double _calculateMonthlyAverage() {
    DateTime now = DateTime.now();
    DateTime oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
    int totalWords = 0;
    int entryCount = 0;

    for (var project in _projects) {
      for (var entry in project.wordCountEntries) {
        if (entry.dateTime.isAfter(oneMonthAgo)) {
          totalWords += entry.wordsAdded;
          entryCount++;
        }
      }
    }

    return entryCount > 0 ? totalWords / entryCount : 0;
  }

  List<FlSpot> _generateWordCountDataForProject(Project project) {
    List<FlSpot> spots = [];
    DateTime now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      DateTime day = now.subtract(Duration(days: i));
      int wordsForDay = 0;

      for (var entry in project.wordCountEntries) {
        if (DateFormat('yyyy-MM-dd').format(entry.dateTime) ==
            DateFormat('yyyy-MM-dd').format(day)) {
          wordsForDay += entry.wordsAdded;
        }
      }

      spots.add(FlSpot(i.toDouble(), wordsForDay.toDouble()));
    }

    return spots.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    double weeklyAverage = _calculateWeeklyAverage();
    double monthlyAverage = _calculateMonthlyAverage();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Tracker'),
      ),
      drawer: const AppNavigationDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Project Name'),
                      ),
                      TextField(
                        controller: _descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                      ),
                      TextField(
                        controller: _wordCountGoalController,
                        decoration:
                            const InputDecoration(labelText: 'Word Count Goal'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _addProject,
                        child: const Text('Add Project'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  flex: 1,
                  child: StopwatchWidget(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Weekly Average Word Count: ${weeklyAverage.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Monthly Average Word Count: ${monthlyAverage.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _projects.length,
                itemBuilder: (context, index) {
                  final project = _projects[index];
                  double progress = project.wordCountGoal == 0
                      ? 0.0
                      : project.currentWordCount / project.wordCountGoal;

                  List<FlSpot> wordCountData =
                      _generateWordCountDataForProject(project);

                  return Card(
                    child: ExpansionTile(
                      title: Text(project.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircularPercentIndicator(
                            radius: 60.0,
                            lineWidth: 10.0,
                            percent: progress.clamp(0.0, 1.0),
                            center: Text(
                              "${(progress * 100).toStringAsFixed(1)}%",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18.0),
                            ),
                            progressColor: progress >= 1.0
                                ? Colors.green
                                : Colors.blueAccent,
                            backgroundColor: Colors.grey.shade300,
                            circularStrokeCap: CircularStrokeCap.round,
                          ),
                          const SizedBox(height: 8),
                          Text('Word Goal: ${project.wordCountGoal}'),
                          Text(
                              'Current Word Count: ${project.currentWordCount}'),
                        ],
                      ),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title:
                                    Text('Description: ${project.description}'),
                              ),
                            ),
                            SizedBox(
                              width: 300,
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: wordCountData,
                                      isCurved: true,
                                      barWidth: 3,
                                      color: Colors.blueAccent,
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color:
                                            Colors.blueAccent.withOpacity(0.3),
                                      ),
                                    ),
                                  ],
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          DateTime now = DateTime.now();
                                          DateTime date = now.subtract(
                                              Duration(days: value.toInt()));
                                          return Text(
                                              DateFormat('EEE').format(date));
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          return Text(value.toInt().toString());
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        ListTile(
                          title: const Text('Edit Project'),
                          trailing: const Icon(Icons.edit),
                          onTap: () => _editProject(index),
                        ),
                        ListTile(
                          title: const Text('Delete Project'),
                          trailing: const Icon(Icons.delete),
                          onTap: () => _deleteProject(index),
                        ),
                        ListTile(
                          title: const Text('Add Word Count'),
                          trailing: const Icon(Icons.add),
                          onTap: () => _showAddWordCountDialog(index),
                        ),
                        ...project.wordCountEntries.map(
                          (entry) => ListTile(
                            title: Text(
                                'Added ${entry.wordsAdded} words on ${entry.dateTime.toLocal()}'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
