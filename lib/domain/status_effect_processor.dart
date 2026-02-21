import 'dart:math';

import '../data/models/battle_state.dart';
import '../data/models/character.dart';
import '../data/models/enemy.dart';
import '../data/models/status_effect.dart';

class StatusTickResult {
  final BattleState state;
  final List<String> messages;
  final bool isStunned;

  const StatusTickResult({
    required this.state,
    this.messages = const [],
    this.isStunned = false,
  });
}

class StatusEffectProcessor {
  final Random _random;

  StatusEffectProcessor({Random? random}) : _random = random ?? Random();

  /// Process start-of-turn effects for an actor.
  /// Applies DoT damage and detects stun.
  StatusTickResult processTurnStart(BattleState state, String actorId) {
    final messages = <String>[];

    final heroIdx = state.party.indexWhere((h) => h.id == actorId);
    if (heroIdx >= 0) {
      final hero = state.party[heroIdx];
      if (hero.statusEffects.isEmpty) {
        return StatusTickResult(state: state);
      }

      // Check stun
      if (hero.statusEffects.any((e) => e.isStun)) {
        messages.add('${hero.name} is stunned and cannot move!');
        return StatusTickResult(
          state: state,
          messages: messages,
          isStunned: true,
        );
      }

      // Apply DoT
      var updatedHero = hero;
      for (final effect in hero.statusEffects) {
        if (effect.isDot && effect.value > 0) {
          final dmg = effect.value;
          final newHp = (updatedHero.currentHp - dmg).clamp(0, 99999);
          updatedHero = updatedHero.copyWith(currentHp: newHp);
          final label = effect.type == StatusEffectType.poison
              ? 'poison'
              : 'burn';
          messages.add('${hero.name} takes $dmg damage from $label!');
        }
      }

      final updatedParty = List<Character>.from(state.party);
      updatedParty[heroIdx] = updatedHero;
      return StatusTickResult(
        state: state.copyWith(party: updatedParty),
        messages: messages,
      );
    }

    final enemyIdx = state.enemies.indexWhere((e) => e.id == actorId);
    if (enemyIdx >= 0) {
      final enemy = state.enemies[enemyIdx];
      if (enemy.statusEffects.isEmpty) {
        return StatusTickResult(state: state);
      }

      // Check stun
      if (enemy.statusEffects.any((e) => e.isStun)) {
        messages.add('${enemy.name} is stunned and cannot move!');
        return StatusTickResult(
          state: state,
          messages: messages,
          isStunned: true,
        );
      }

      // Apply DoT
      var updatedEnemy = enemy;
      for (final effect in enemy.statusEffects) {
        if (effect.isDot && effect.value > 0) {
          final dmg = effect.value;
          final newHp =
              (updatedEnemy.currentHp - dmg).clamp(0, enemy.stats.maxHp);
          updatedEnemy = updatedEnemy.copyWith(currentHp: newHp);
          final label = effect.type == StatusEffectType.poison
              ? 'poison'
              : 'burn';
          messages.add('${enemy.name} takes $dmg damage from $label!');
        }
      }

      final updatedEnemies = List<Enemy>.from(state.enemies);
      updatedEnemies[enemyIdx] = updatedEnemy;
      return StatusTickResult(
        state: state.copyWith(enemies: updatedEnemies),
        messages: messages,
      );
    }

    return StatusTickResult(state: state);
  }

  /// Tick down all durations at round end. Remove expired effects.
  BattleState tickDownDurations(BattleState state, List<String> messages) {
    final updatedParty = state.party.map((hero) {
      if (hero.statusEffects.isEmpty) return hero;
      final newEffects = <StatusEffect>[];
      for (final effect in hero.statusEffects) {
        final ticked = effect.copyWith(duration: effect.duration - 1);
        if (ticked.isExpired) {
          messages.add('${effect.displayName} wore off from ${hero.name}.');
        } else {
          newEffects.add(ticked);
        }
      }
      return hero.copyWith(statusEffects: newEffects);
    }).toList();

    final updatedEnemies = state.enemies.map((enemy) {
      if (enemy.statusEffects.isEmpty) return enemy;
      final newEffects = <StatusEffect>[];
      for (final effect in enemy.statusEffects) {
        final ticked = effect.copyWith(duration: effect.duration - 1);
        if (ticked.isExpired) {
          messages.add('${effect.displayName} wore off from ${enemy.name}.');
        } else {
          newEffects.add(ticked);
        }
      }
      return enemy.copyWith(statusEffects: newEffects);
    }).toList();

    return state.copyWith(party: updatedParty, enemies: updatedEnemies);
  }

  /// Apply a status effect with stacking rules.
  List<StatusEffect> applyEffect(
      List<StatusEffect> current, StatusEffect newEffect) {
    final existing = current.indexWhere((e) => e.type == newEffect.type);
    if (existing >= 0) {
      // Refresh: keep higher value and longer duration
      final old = current[existing];
      final merged = StatusEffect(
        type: newEffect.type,
        duration: max(old.duration, newEffect.duration),
        value: max(old.value, newEffect.value),
        sourceId: newEffect.sourceId,
      );
      return [
        for (int i = 0; i < current.length; i++)
          if (i == existing) merged else current[i],
      ];
    }
    return [...current, newEffect];
  }

  /// Roll whether a status effect should be applied.
  bool rollEffect(double chance) {
    return _random.nextDouble() < chance;
  }

  /// Calculate stat modifiers from active status effects.
  /// Returns multiplier (e.g., 1.25 for 25% ATK Up).
  double getAttackMultiplier(List<StatusEffect> effects) {
    double mult = 1.0;
    for (final e in effects) {
      if (e.type == StatusEffectType.atkUp) mult += e.value / 100;
      if (e.type == StatusEffectType.atkDown) mult -= e.value / 100;
    }
    return mult.clamp(0.25, 3.0);
  }

  double getDefenseMultiplier(List<StatusEffect> effects) {
    double mult = 1.0;
    for (final e in effects) {
      if (e.type == StatusEffectType.defUp) mult += e.value / 100;
      if (e.type == StatusEffectType.defDown) mult -= e.value / 100;
    }
    return mult.clamp(0.25, 3.0);
  }
}
