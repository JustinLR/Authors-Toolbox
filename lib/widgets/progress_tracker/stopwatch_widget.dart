// stopwatch_widget.dart
import 'dart:async';
import 'package:authors_toolbox/screens/progress_tracker/progress_tracker_screen.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

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
