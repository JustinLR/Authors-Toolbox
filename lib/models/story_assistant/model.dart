class Model {
  final String model;
  final String systemPrompt;
  final Map<String, dynamic> parameters;
  final bool
      isOpenToErotica; // New flag to check if the assistant is open to erotica

  Model(
      {required this.model,
      required this.systemPrompt,
      required this.parameters,
      required this.isOpenToErotica});

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      model: json['model'],
      systemPrompt: json['system_prompt'],
      parameters: Map<String, dynamic>.from(json['parameters']),
      isOpenToErotica: json['is_open_to_erotica'] ??
          false, // Default to false if not specified
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'system_prompt': systemPrompt,
      'parameters': parameters,
      'is_open_to_erotica': isOpenToErotica, // Include the new flag
    };
  }
}
