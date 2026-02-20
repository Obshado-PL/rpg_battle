class Stats {
  final int maxHp;
  final int maxMp;
  final int attack;
  final int defense;
  final int magicAttack;
  final int magicDefense;
  final int speed;

  const Stats({
    required this.maxHp,
    required this.maxMp,
    required this.attack,
    required this.defense,
    required this.magicAttack,
    required this.magicDefense,
    required this.speed,
  });

  Stats copyWith({
    int? maxHp,
    int? maxMp,
    int? attack,
    int? defense,
    int? magicAttack,
    int? magicDefense,
    int? speed,
  }) {
    return Stats(
      maxHp: maxHp ?? this.maxHp,
      maxMp: maxMp ?? this.maxMp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      magicAttack: magicAttack ?? this.magicAttack,
      magicDefense: magicDefense ?? this.magicDefense,
      speed: speed ?? this.speed,
    );
  }

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      maxHp: json['maxHp'] as int,
      maxMp: json['maxMp'] as int,
      attack: json['attack'] as int,
      defense: json['defense'] as int,
      magicAttack: json['magicAttack'] as int,
      magicDefense: json['magicDefense'] as int,
      speed: json['speed'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxHp': maxHp,
      'maxMp': maxMp,
      'attack': attack,
      'defense': defense,
      'magicAttack': magicAttack,
      'magicDefense': magicDefense,
      'speed': speed,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stats &&
          maxHp == other.maxHp &&
          maxMp == other.maxMp &&
          attack == other.attack &&
          defense == other.defense &&
          magicAttack == other.magicAttack &&
          magicDefense == other.magicDefense &&
          speed == other.speed;

  @override
  int get hashCode => Object.hash(
        maxHp, maxMp, attack, defense, magicAttack, magicDefense, speed,
      );
}
