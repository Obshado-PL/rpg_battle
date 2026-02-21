import 'dart:math';

import '../data/models/character.dart';
import '../data/models/enemy.dart';
import '../data/models/equipment.dart';
import 'equipment_system.dart';

class TurnManager {
  final Random _random;
  final Map<String, Equipment> _equipment;

  TurnManager({Random? random, Map<String, Equipment>? equipment})
      : _random = random ?? Random(),
        _equipment = equipment ?? {};

  /// Returns ordered list of actor IDs sorted by speed (descending).
  /// Dead actors are excluded. Ties broken by small random factor.
  List<String> calculateTurnOrder({
    required List<Character> party,
    required List<Enemy> enemies,
  }) {
    final actors = <_ActorSpeed>[];

    for (final hero in party) {
      if (!hero.isAlive) continue;
      final effectiveSpeed =
          EquipmentSystem.computeEffectiveStats(hero, _equipment).speed;
      actors.add(_ActorSpeed(
        id: hero.id,
        speed: effectiveSpeed + _random.nextInt(5),
      ));
    }

    for (final enemy in enemies) {
      if (!enemy.isAlive) continue;
      actors.add(_ActorSpeed(
        id: enemy.id,
        speed: enemy.stats.speed + _random.nextInt(5),
      ));
    }

    actors.sort((a, b) => b.speed.compareTo(a.speed));
    return actors.map((a) => a.id).toList();
  }
}

class _ActorSpeed {
  final String id;
  final int speed;

  _ActorSpeed({required this.id, required this.speed});
}
