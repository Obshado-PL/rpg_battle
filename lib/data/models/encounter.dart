class Encounter {
  final String id;
  final String name;
  final List<String> enemyIds;
  final int difficulty;
  final String backgroundGradientStart;
  final String backgroundGradientEnd;

  const Encounter({
    required this.id,
    required this.name,
    required this.enemyIds,
    this.difficulty = 1,
    this.backgroundGradientStart = '0xFF1a237e',
    this.backgroundGradientEnd = '0xFF4a148c',
  });

  factory Encounter.fromJson(Map<String, dynamic> json) {
    return Encounter(
      id: json['id'] as String,
      name: json['name'] as String,
      enemyIds: (json['enemyIds'] as List<dynamic>).cast<String>(),
      difficulty: json['difficulty'] as int? ?? 1,
      backgroundGradientStart:
          json['backgroundGradientStart'] as String? ?? '0xFF1a237e',
      backgroundGradientEnd:
          json['backgroundGradientEnd'] as String? ?? '0xFF4a148c',
    );
  }
}
