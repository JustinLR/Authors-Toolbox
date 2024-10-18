// lib/model/model.dart
class Model {
  final String name;
  final String description;
  final List<String> personalityTraits;
  final Map<String, String> preferences;
  final String model;
  final Map<String, dynamic> parameters;
  final String systemPrompt;

  Model({
    required this.name,
    required this.description,
    required this.personalityTraits,
    required this.preferences,
    required this.model,
    required this.parameters,
    required this.systemPrompt,
  });

  // Factory method to create a Model instance from JSON
  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      name: json['name'] as String? ?? 'Unknown Name',
      description:
          json['description'] as String? ?? 'No description available.',
      personalityTraits: List<String>.from(json['personality']['traits'] ?? []),
      preferences: Map<String, String>.from(json['preferences'] ?? {}),
      model: json['model'] as String? ?? 'default-model',
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      systemPrompt:
          json['system_prompt'] as String? ?? 'No system prompt provided.',
    );
  }

  // Method to convert Model instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'personality': {
        'traits': personalityTraits,
      },
      'preferences': preferences,
      'model': model,
      'parameters': parameters,
      'system_prompt': systemPrompt,
    };
  }
}
