enum Difficulty { easy, normal, hard }

class DifficultyConfig {
  final Difficulty difficulty;
  final double enemyStatScale;
  final double rewardScale;

  const DifficultyConfig._({
    required this.difficulty,
    required this.enemyStatScale,
    required this.rewardScale,
  });

  static const configs = {
    Difficulty.easy: DifficultyConfig._(
      difficulty: Difficulty.easy,
      enemyStatScale: 0.7,
      rewardScale: 1.3,
    ),
    Difficulty.normal: DifficultyConfig._(
      difficulty: Difficulty.normal,
      enemyStatScale: 1.0,
      rewardScale: 1.0,
    ),
    Difficulty.hard: DifficultyConfig._(
      difficulty: Difficulty.hard,
      enemyStatScale: 1.5,
      rewardScale: 0.7,
    ),
  };

  static DifficultyConfig get(Difficulty d) => configs[d]!;
}
