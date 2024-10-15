// project_manager.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:authors_toolbox/models/progress_tracker/project.dart';

class ProjectManager {
  Future<List<Project>> loadProjects() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? projectsJson = prefs.getString('projects');
    if (projectsJson != null) {
      return (json.decode(projectsJson) as List)
          .map((data) => Project.fromJson(data))
          .toList();
    }
    return [];
  }

  Future<void> saveProjects(List<Project> projects) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String projectsJson = json.encode(projects.map((p) => p.toJson()).toList());
    await prefs.setString('projects', projectsJson);
  }
}
