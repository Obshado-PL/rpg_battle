class HeroSpriteHelper {
  static const _base = 'assets/arts/Heros/Epic Characters 1 - Animated/'
      '50 - Characters - 64x64 + 3 Animations';

  /// Static character image (64x64)
  static String staticImage(int spriteId) => '$_base/$spriteId/$spriteId.png';

  /// Idle animation frame (1-4)
  static String idleFrame(int spriteId, int frame) =>
      '$_base/$spriteId/idle$frame.png';

  /// Attack animation frame (1-4)
  static String attackFrame(int spriteId, int frame) =>
      '$_base/$spriteId/attack$frame.png';

  /// Walk animation frame (1-4)
  static String walkFrame(int spriteId, int frame) =>
      '$_base/$spriteId/walk$frame.png';

  /// All idle frames for a sprite
  static List<String> idleFrames(int spriteId) =>
      List.generate(4, (i) => idleFrame(spriteId, i + 1));

  /// All attack frames for a sprite
  static List<String> attackFrames(int spriteId) =>
      List.generate(4, (i) => attackFrame(spriteId, i + 1));

  /// All walk frames for a sprite
  static List<String> walkFrames(int spriteId) =>
      List.generate(4, (i) => walkFrame(spriteId, i + 1));
}
