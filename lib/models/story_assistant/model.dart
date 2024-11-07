class Model {
  final String model;
  final String name;
  final String systemPrompt;
  final Map<String, double> parameters;

  Model({
    required this.model,
    required this.name,
    required this.systemPrompt,
    required this.parameters,
  });

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      model: json['model'] as String,
      name: json['name'] as String,
      systemPrompt: json['system_prompt'] as String,
      parameters: (json['parameters'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'name': name,
      'system_prompt': systemPrompt,
      'parameters': parameters,
    };
  }
}
