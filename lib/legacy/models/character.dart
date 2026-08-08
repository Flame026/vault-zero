class Character {
  final int? id;
  final String name;
  final String faction;
  final String characterClass;
  final String title;
  final String skill1;
  final String skill2;
  final String skill3;
  final String skill4;

  Character({
    this.id,
    required this.name,
    required this.faction,
    required this.characterClass,
    required this.title,
    required this.skill1,
    required this.skill2,
    required this.skill3,
    required this.skill4,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'faction': faction,
      'characterClass': characterClass,
      'title': title,
      'skill1': skill1,
      'skill2': skill2,
      'skill3': skill3,
      'skill4': skill4,
    };
  }

  factory Character.fromMap(Map<String, dynamic> map) {
    return Character(
      id: map['id'] as int?,
      name: map['name'] as String,
      faction: map['faction'] as String,
      characterClass: map['characterClass'] as String,
      title: map['title'] as String,
      skill1: map['skill1'] as String,
      skill2: map['skill2'] as String,
      skill3: map['skill3'] as String,
      skill4: map['skill4'] as String,
    );
  }

  Character copyWith({
    int? id,
    String? name,
    String? faction,
    String? characterClass,
    String? title,
    String? skill1,
    String? skill2,
    String? skill3,
    String? skill4,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      faction: faction ?? this.faction,
      characterClass: characterClass ?? this.characterClass,
      title: title ?? this.title,
      skill1: skill1 ?? this.skill1,
      skill2: skill2 ?? this.skill2,
      skill3: skill3 ?? this.skill3,
      skill4: skill4 ?? this.skill4,
    );
  }
}