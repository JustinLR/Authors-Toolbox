import 'package:flutter/material.dart';
import 'package:authors_toolbox/widgets/navigation_drawer.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart for graphs
import 'package:intl/intl.dart'; // For date formatting

// Project model to store project details and word count progress entries
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

  // Convert Project to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'wordCountGoal': wordCountGoal,
        'currentWordCount': currentWordCount,
        'wordCountEntries':
            wordCountEntries.map((entry) => entry.toJson()).toList(),
      };

  // Create Project from JSON
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

// WordCountEntry to record word count added and the timestamp
class WordCountEntry {
  int wordsAdded;
  DateTime dateTime;

  WordCountEntry({required this.wordsAdded, required this.dateTime});

  // Convert WordCountEntry to JSON
  Map<String, dynamic> toJson() => {
        'wordsAdded': wordsAdded,
        'dateTime': dateTime.toIso8601String(),
      };

  // Create WordCountEntry from JSON
  factory WordCountEntry.fromJson(Map<String, dynamic> json) {
    return WordCountEntry(
      wordsAdded: json['wordsAdded'],
      dateTime: DateTime.parse(json['dateTime']),
    );
  }
}

class StopwatchWidget extends StatefulWidget {
  @override
  _StopwatchWidgetState createState() => _StopwatchWidgetState();
}

class _StopwatchWidgetState extends State<StopwatchWidget> {
  late Timer _timer;
  int _seconds = 0;
  bool _isRunning = false;
  int? _alarmSeconds;
  int _maxSeconds = 24 * 3600; // Max value set to 24 hours in seconds
  Color _progressColor = Colors.blueAccent;

  // Controller for the Set Alarm input field
  final TextEditingController _alarmController = TextEditingController();

  // Helper method to convert a string in 'HH:MM:SS' format to total seconds
  int _parseTimeToSeconds(String time) {
    final parts = time.split(':');
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = int.tryParse(parts[2]) ?? 0;
      return (hours * 3600) + (minutes * 60) + seconds;
    }
    return 0;
  }

  // Helper method to convert total seconds to 'HH:MM:SS' format
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
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;

          if (_alarmSeconds != null && _seconds >= _alarmSeconds!) {
            _stopStopwatch();
            _progressColor = Colors.red;
            _showAlarmDialog();
          }

          if (_seconds >= _maxSeconds ||
              (_alarmSeconds != null && _seconds >= _alarmSeconds!)) {
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
    _timer.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  // Reset the stopwatch
  void _resetStopwatch() {
    _timer.cancel();
    setState(() {
      _seconds = 0;
      _isRunning = false;
      _alarmSeconds = null;
      _progressColor = Colors.blueAccent;
      _alarmController.clear();
    });
  }

  // Show an alarm dialog when time is up
  void _showAlarmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Alarm"),
          content: Text("Time's up!"),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Set an alarm in seconds
  void _setAlarm(int seconds) {
    setState(() {
      _alarmSeconds = seconds;
      _progressColor = Colors.blueAccent;
    });
  }

  // Automatically format the time input as HH:MM:SS
  void _onAlarmTimeChanged(String value) {
    String digitsOnly = value.replaceAll(
        RegExp(r'[^0-9]'), ''); // Remove non-numeric characters
    if (digitsOnly.length > 6) {
      digitsOnly =
          digitsOnly.substring(0, 6); // Limit input to 6 digits (HHMMSS)
    }

    String formattedTime;
    if (digitsOnly.length <= 2) {
      formattedTime = digitsOnly.padLeft(2, '0'); // Format as 'HH'
    } else if (digitsOnly.length <= 4) {
      formattedTime = digitsOnly.substring(0, 2) +
          ':' +
          digitsOnly.substring(2).padLeft(2, '0'); // Format as 'HH:MM'
    } else {
      formattedTime = digitsOnly.substring(0, 2) +
          ':' +
          digitsOnly.substring(2, 4) +
          ':' +
          digitsOnly.substring(4).padLeft(2, '0'); // Format as 'HH:MM:SS'
    }

    _alarmController.value = TextEditingValue(
      text: formattedTime,
      selection: TextSelection.collapsed(offset: formattedTime.length),
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
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          ),
          progressColor: _progressColor,
          backgroundColor: Colors.grey.shade300,
          circularStrokeCap: CircularStrokeCap.round,
        ),
        SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _startStopwatch,
              child: Text("Start"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isRunning ? _stopStopwatch : null,
              child: Text("Stop"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _resetStopwatch,
              child: Text("Reset"),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 150,
              child: TextField(
                controller: _alarmController,
                onChanged: _onAlarmTimeChanged, // Call the time formatter
                decoration: InputDecoration(labelText: 'Set Alarm (HH:MM:SS)'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ProgressTrackerScreen extends StatefulWidget {
  @override
  _ProgressTrackerScreenState createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends State<ProgressTrackerScreen> {
  // List to store projects
  List<Project> _projects = [];

  // Controllers for text input fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _wordCountGoalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjects(); // Load projects when the screen initializes
  }

  // Function to load projects from SharedPreferences
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

  // Function to save projects to SharedPreferences
  Future<void> _saveProjects() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String projectsJson =
        json.encode(_projects.map((p) => p.toJson()).toList());
    await prefs.setString('projects', projectsJson);
  }

  // Function to add a new project
  void _addProject() {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _wordCountGoalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    final wordCountGoal = int.tryParse(_wordCountGoalController.text);
    if (wordCountGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Word count goal must be a number')),
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

  // Function to edit a project
  void _editProject(int index) {
    _nameController.text = _projects[index].name;
    _descriptionController.text = _projects[index].description;
    _wordCountGoalController.text = _projects[index].wordCountGoal.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Project"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Project Name'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: _wordCountGoalController,
                decoration: InputDecoration(labelText: 'Word Count Goal'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              child: Text("Save"),
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
                    SnackBar(content: Text('Word count goal must be a number')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Function to delete a project
  void _deleteProject(int index) {
    setState(() {
      _projects.removeAt(index);
    });
    _saveProjects(); // Save to SharedPreferences after deletion
  }

  // Function to add word count progress
  void _addWordCount(int index, int wordCount) {
    setState(() {
      _projects[index].currentWordCount += wordCount;
      _projects[index].wordCountEntries.add(
            WordCountEntry(wordsAdded: wordCount, dateTime: DateTime.now()),
          );
    });
    _saveProjects(); // Save the updated project list to SharedPreferences
  }

  // Function to show a dialog for adding word count
  void _showAddWordCountDialog(int index) {
    final _wordCountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Word Count"),
          content: TextField(
            controller: _wordCountController,
            decoration: InputDecoration(labelText: 'Words Written'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            ElevatedButton(
              child: Text("Add"),
              onPressed: () {
                final wordCount = int.tryParse(_wordCountController.text);
                if (wordCount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid word count')),
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

// Calculate the average weekly word count
  double _calculateWeeklyAverage() {
    DateTime now = DateTime.now();
    DateTime oneWeekAgo = now.subtract(Duration(days: 7));
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

// Calculate the average monthly word count
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

  // Generate data for the word count graph for a specific project (weekly data points)
  List<FlSpot> _generateWordCountDataForProject(Project project) {
    List<FlSpot> spots = [];
    DateTime now = DateTime.now();

    // Loop through the last 7 days and accumulate word counts for each day
    for (int i = 0; i < 7; i++) {
      DateTime day = now.subtract(Duration(days: i));
      int wordsForDay = 0;

      // Sum up the word count for this day from the project's word count entries
      for (var entry in project.wordCountEntries) {
        if (DateFormat('yyyy-MM-dd').format(entry.dateTime) ==
            DateFormat('yyyy-MM-dd').format(day)) {
          wordsForDay += entry.wordsAdded;
        }
      }

      // Add the day's total word count as a FlSpot (x = day index, y = words added)
      spots.add(FlSpot(i.toDouble(), wordsForDay.toDouble()));
    }

    // Reverse the spots list to show the most recent day on the right
    return spots.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    double weeklyAverage = _calculateWeeklyAverage();
    double monthlyAverage = _calculateMonthlyAverage();

    return Scaffold(
      appBar: AppBar(
        title: Text('Progress Tracker'),
      ),
      drawer: AppNavigationDrawer(),
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
                        decoration: InputDecoration(labelText: 'Project Name'),
                      ),
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(labelText: 'Description'),
                      ),
                      TextField(
                        controller: _wordCountGoalController,
                        decoration:
                            InputDecoration(labelText: 'Word Count Goal'),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _addProject,
                        child: Text('Add Project'),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: StopwatchWidget(),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Display the weekly and monthly averages
            Text(
              'Weekly Average Word Count: ${weeklyAverage.toStringAsFixed(1)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Monthly Average Word Count: ${monthlyAverage.toStringAsFixed(1)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: _projects.length,
                itemBuilder: (context, index) {
                  final project = _projects[index];
                  double progress = project.wordCountGoal == 0
                      ? 0.0
                      : project.currentWordCount / project.wordCountGoal;

                  // Initialize wordCountData before it's used
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
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18.0),
                            ),
                            progressColor: progress >= 1.0
                                ? Colors.green
                                : Colors.blueAccent,
                            backgroundColor: Colors.grey.shade300,
                            circularStrokeCap: CircularStrokeCap.round,
                          ),
                          SizedBox(height: 8),
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
                          title: Text('Edit Project'),
                          trailing: Icon(Icons.edit),
                          onTap: () => _editProject(index),
                        ),
                        ListTile(
                          title: Text('Delete Project'),
                          trailing: Icon(Icons.delete),
                          onTap: () => _deleteProject(index),
                        ),
                        ListTile(
                          title: Text('Add Word Count'),
                          trailing: Icon(Icons.add),
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
