class Character {
  // Basic Information (required fields)
  String name;
  int age;
  String role;

  // Basic Information (optional)
  String? gender;
  String? race;
  String? occupation;
  String? personality;

  // Physical Appearance (optional)
  String? height;
  String? weight;
  String? build;
  String? hair;
  String? eyes;
  String? skin;
  String? clothingStyle;
  String? physicalTraits;

  // Abilities (optional)
  bool hasPowers;
  String? powerType; // Nullable if no powers
  String? powerOrigin; // Nullable if no powers
  List<String>? skills;
  List<String>? weapons;
  List<String>? weaknesses;

  // Psychological Traits (optional)
  String? motivation;
  List<String>? fears;
  List<String>? likes;
  List<String>? dislikes;
  List<String>? ticksOrQuirks;
  String? moralAlignment;

  // Backstory (optional)
  String? birthplace;
  String? backstorySummary;
  List<String>? keyLifeEvents;
  String? educationOrTraining;

  // Relationships (optional)
  List<String>? family;
  List<String>? romanticRelationships;
  List<String>? friendsAndAllies;
  List<String>? enemies;
  List<String>? pets;

  // Miscellaneous (optional)
  List<String>? hobbies;
  List<String>? languagesSpoken;
  String? religion;
  String? politicalViews;
  String? currentResidence;
  List<String>? possessions;

  Character({
    // Required fields
    required this.name,
    required this.age,
    required this.role,

    // Optional fields
    this.gender,
    this.race,
    this.occupation,
    this.personality,
    this.height,
    this.weight,
    this.build,
    this.hair,
    this.eyes,
    this.skin,
    this.clothingStyle,
    this.physicalTraits,
    this.hasPowers = false, // Default to false
    this.powerType,
    this.powerOrigin,
    this.skills,
    this.weapons,
    this.weaknesses,
    this.motivation,
    this.fears,
    this.likes,
    this.dislikes,
    this.ticksOrQuirks,
    this.moralAlignment,
    this.birthplace,
    this.backstorySummary,
    this.keyLifeEvents,
    this.educationOrTraining,
    this.family,
    this.romanticRelationships,
    this.friendsAndAllies,
    this.enemies,
    this.pets,
    this.hobbies,
    this.languagesSpoken,
    this.religion,
    this.politicalViews,
    this.currentResidence,
    this.possessions,
  });

  // Factory constructor for creating a Character from JSON
  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: json['name'],
      age: json['age'],
      role: json['role'],
      gender: json['gender'],
      race: json['race'],
      occupation: json['occupation'],
      personality: json['personality'],
      height: json['height'],
      weight: json['weight'],
      build: json['build'],
      hair: json['hair'],
      eyes: json['eyes'],
      skin: json['skin'],
      clothingStyle: json['clothingStyle'],
      physicalTraits: json['physicalTraits'],
      hasPowers: json['hasPowers'] ?? false, // Default to false if null
      powerType: json['powerType'],
      powerOrigin: json['powerOrigin'],
      skills:
          (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList(),
      weapons:
          (json['weapons'] as List<dynamic>?)?.map((e) => e as String).toList(),
      weaknesses: (json['weaknesses'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      motivation: json['motivation'],
      fears:
          (json['fears'] as List<dynamic>?)?.map((e) => e as String).toList(),
      likes:
          (json['likes'] as List<dynamic>?)?.map((e) => e as String).toList(),
      dislikes: (json['dislikes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      ticksOrQuirks: (json['ticksOrQuirks'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      moralAlignment: json['moralAlignment'],
      birthplace: json['birthplace'],
      backstorySummary: json['backstorySummary'],
      keyLifeEvents: (json['keyLifeEvents'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      educationOrTraining: json['educationOrTraining'],
      family:
          (json['family'] as List<dynamic>?)?.map((e) => e as String).toList(),
      romanticRelationships: (json['romanticRelationships'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      friendsAndAllies: (json['friendsAndAllies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      enemies:
          (json['enemies'] as List<dynamic>?)?.map((e) => e as String).toList(),
      pets: (json['pets'] as List<dynamic>?)?.map((e) => e as String).toList(),
      hobbies:
          (json['hobbies'] as List<dynamic>?)?.map((e) => e as String).toList(),
      languagesSpoken: (json['languagesSpoken'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      religion: json['religion'],
      politicalViews: json['politicalViews'],
      currentResidence: json['currentResidence'],
      possessions: (json['possessions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  // Method to convert Character to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'role': role,
      'gender': gender,
      'race': race,
      'occupation': occupation,
      'personality': personality,
      'height': height,
      'weight': weight,
      'build': build,
      'hair': hair,
      'eyes': eyes,
      'skin': skin,
      'clothingStyle': clothingStyle,
      'physicalTraits': physicalTraits,
      'hasPowers': hasPowers,
      'powerType': powerType,
      'powerOrigin': powerOrigin,
      'skills': skills,
      'weapons': weapons,
      'weaknesses': weaknesses,
      'motivation': motivation,
      'fears': fears,
      'likes': likes,
      'dislikes': dislikes,
      'ticksOrQuirks': ticksOrQuirks,
      'moralAlignment': moralAlignment,
      'birthplace': birthplace,
      'backstorySummary': backstorySummary,
      'keyLifeEvents': keyLifeEvents,
      'educationOrTraining': educationOrTraining,
      'family': family,
      'romanticRelationships': romanticRelationships,
      'friendsAndAllies': friendsAndAllies,
      'enemies': enemies,
      'pets': pets,
      'hobbies': hobbies,
      'languagesSpoken': languagesSpoken,
      'religion': religion,
      'politicalViews': politicalViews,
      'currentResidence': currentResidence,
      'possessions': possessions,
    };
  }
}
