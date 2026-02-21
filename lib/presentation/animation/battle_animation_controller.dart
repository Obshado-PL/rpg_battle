import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/battle_engine.dart';

enum VfxType {
  actorLunge,
  targetHitFlash,
  targetShake,
  damageNumber,
  healNumber,
  missText,
  skillEffect,
  defendShield,
  deathFadeOut,
  screenFlash,
  screenShake,
}

class VfxCommand {
  final String id;
  final VfxType type;
  final String? targetId;
  final String? actorId;
  final int? value;
  final bool isCritical;
  final String? effectKey;
  final String? text;
  final Duration startDelay;
  final Duration duration;

  VfxCommand({
    required this.type,
    this.targetId,
    this.actorId,
    this.value,
    this.isCritical = false,
    this.effectKey,
    this.text,
    this.startDelay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
  }) : id = '${type.name}_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';
}

class BattleAnimationController extends ChangeNotifier {
  final List<VfxCommand> _activeCommands = [];
  bool _disposed = false;

  List<VfxCommand> get activeCommands => List.unmodifiable(_activeCommands);

  bool hasCommandForTarget(String targetId, VfxType type) {
    return _activeCommands.any((c) => c.targetId == targetId && c.type == type);
  }

  bool hasCommandForActor(String actorId, VfxType type) {
    return _activeCommands.any((c) => c.actorId == actorId && c.type == type);
  }

  bool hasScreenCommand(VfxType type) {
    return _activeCommands.any((c) => c.type == type);
  }

  Future<void> playSequence(List<BattleAnimationEvent> events) async {
    if (events.isEmpty || _disposed) return;

    final commands = _buildCommandSequence(events);
    if (commands.isEmpty) return;

    final totalDuration = _calculateTotalDuration(commands);

    for (final cmd in commands) {
      if (_disposed) return;

      Future.delayed(cmd.startDelay, () {
        if (_disposed) return;
        _activeCommands.add(cmd);
        notifyListeners();

        Future.delayed(cmd.duration, () {
          if (_disposed) return;
          _activeCommands.remove(cmd);
          notifyListeners();
        });
      });
    }

    await Future.delayed(totalDuration);
  }

  void clear() {
    _activeCommands.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _activeCommands.clear();
    super.dispose();
  }

  Duration _calculateTotalDuration(List<VfxCommand> commands) {
    Duration max = Duration.zero;
    for (final cmd in commands) {
      final end = cmd.startDelay + cmd.duration;
      if (end > max) max = end;
    }
    // Add a small buffer after the last visual clears
    return max + const Duration(milliseconds: 100);
  }

  List<VfxCommand> _buildCommandSequence(List<BattleAnimationEvent> events) {
    final commands = <VfxCommand>[];
    Duration baseOffset = Duration.zero;

    for (final event in events) {
      switch (event.type) {
        case 'attack':
          commands.addAll(_buildAttackCommands(event, baseOffset));
          baseOffset += const Duration(milliseconds: 500);
          break;
        case 'skill':
          commands.addAll(_buildSkillCommands(event, baseOffset));
          baseOffset += const Duration(milliseconds: 600);
          break;
        case 'heal':
          commands.addAll(_buildHealCommands(event, baseOffset));
          baseOffset += const Duration(milliseconds: 400);
          break;
        case 'damage':
          commands.addAll(_buildDamageCommands(event, baseOffset));
          baseOffset += const Duration(milliseconds: 500);
          break;
        case 'miss':
          commands.addAll(_buildMissCommands(event, baseOffset));
          baseOffset += const Duration(milliseconds: 400);
          break;
        case 'defend':
          commands.addAll(_buildDefendCommands(event, baseOffset));
          baseOffset += const Duration(milliseconds: 300);
          break;
        case 'death':
          commands.addAll(_buildDeathCommands(event, baseOffset));
          baseOffset += const Duration(milliseconds: 300);
          break;
      }
    }

    return commands;
  }

  List<VfxCommand> _buildAttackCommands(
      BattleAnimationEvent event, Duration offset) {
    final cmds = <VfxCommand>[];

    if (event.isCritical) {
      cmds.add(VfxCommand(
        type: VfxType.screenFlash,
        startDelay: offset,
        duration: const Duration(milliseconds: 200),
      ));
    }

    cmds.add(VfxCommand(
      type: VfxType.actorLunge,
      actorId: event.actorId,
      startDelay: offset + (event.isCritical
          ? const Duration(milliseconds: 50)
          : Duration.zero),
      duration: const Duration(milliseconds: 250),
    ));

    cmds.add(VfxCommand(
      type: VfxType.targetHitFlash,
      targetId: event.targetId,
      startDelay: offset + const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 150),
    ));

    cmds.add(VfxCommand(
      type: VfxType.targetShake,
      targetId: event.targetId,
      startDelay: offset + const Duration(milliseconds: 200),
      duration: Duration(milliseconds: event.isCritical ? 400 : 300),
    ));

    if (event.value != null) {
      cmds.add(VfxCommand(
        type: VfxType.damageNumber,
        targetId: event.targetId,
        value: event.value,
        isCritical: event.isCritical,
        startDelay: offset + const Duration(milliseconds: 300),
        duration: const Duration(milliseconds: 800),
      ));
    }

    if (event.isCritical) {
      cmds.add(VfxCommand(
        type: VfxType.screenShake,
        startDelay: offset + const Duration(milliseconds: 200),
        duration: const Duration(milliseconds: 300),
      ));
    }

    return cmds;
  }

  List<VfxCommand> _buildSkillCommands(
      BattleAnimationEvent event, Duration offset) {
    final cmds = <VfxCommand>[];

    cmds.add(VfxCommand(
      type: VfxType.actorLunge,
      actorId: event.actorId,
      startDelay: offset,
      duration: const Duration(milliseconds: 200),
    ));

    cmds.add(VfxCommand(
      type: VfxType.skillEffect,
      targetId: event.targetId,
      effectKey: event.effectKey,
      startDelay: offset + const Duration(milliseconds: 150),
      duration: const Duration(milliseconds: 600),
    ));

    if (event.targetId != null) {
      cmds.add(VfxCommand(
        type: VfxType.targetHitFlash,
        targetId: event.targetId,
        startDelay: offset + const Duration(milliseconds: 400),
        duration: const Duration(milliseconds: 150),
      ));

      cmds.add(VfxCommand(
        type: VfxType.targetShake,
        targetId: event.targetId,
        startDelay: offset + const Duration(milliseconds: 400),
        duration: const Duration(milliseconds: 300),
      ));
    }

    if (event.value != null) {
      cmds.add(VfxCommand(
        type: VfxType.damageNumber,
        targetId: event.targetId,
        value: event.value,
        isCritical: event.isCritical,
        startDelay: offset + const Duration(milliseconds: 500),
        duration: const Duration(milliseconds: 800),
      ));
    }

    if (event.isCritical) {
      cmds.add(VfxCommand(
        type: VfxType.screenFlash,
        startDelay: offset + const Duration(milliseconds: 100),
        duration: const Duration(milliseconds: 200),
      ));
      cmds.add(VfxCommand(
        type: VfxType.screenShake,
        startDelay: offset + const Duration(milliseconds: 200),
        duration: const Duration(milliseconds: 300),
      ));
    }

    return cmds;
  }

  List<VfxCommand> _buildHealCommands(
      BattleAnimationEvent event, Duration offset) {
    return [
      VfxCommand(
        type: VfxType.skillEffect,
        targetId: event.targetId,
        effectKey: event.effectKey ?? 'heal',
        startDelay: offset,
        duration: const Duration(milliseconds: 700),
      ),
      if (event.value != null)
        VfxCommand(
          type: VfxType.healNumber,
          targetId: event.targetId,
          value: event.value,
          startDelay: offset + const Duration(milliseconds: 200),
          duration: const Duration(milliseconds: 800),
        ),
    ];
  }

  List<VfxCommand> _buildDamageCommands(
      BattleAnimationEvent event, Duration offset) {
    final cmds = <VfxCommand>[];

    if (event.isCritical) {
      cmds.add(VfxCommand(
        type: VfxType.screenFlash,
        startDelay: offset,
        duration: const Duration(milliseconds: 200),
      ));
    }

    cmds.add(VfxCommand(
      type: VfxType.targetHitFlash,
      targetId: event.targetId,
      startDelay: offset,
      duration: const Duration(milliseconds: 150),
    ));

    cmds.add(VfxCommand(
      type: VfxType.targetShake,
      targetId: event.targetId,
      startDelay: offset,
      duration: Duration(milliseconds: event.isCritical ? 400 : 300),
    ));

    if (event.value != null) {
      cmds.add(VfxCommand(
        type: VfxType.damageNumber,
        targetId: event.targetId,
        value: event.value,
        isCritical: event.isCritical,
        startDelay: offset + const Duration(milliseconds: 100),
        duration: const Duration(milliseconds: 800),
      ));
    }

    if (event.isCritical) {
      cmds.add(VfxCommand(
        type: VfxType.screenShake,
        startDelay: offset,
        duration: const Duration(milliseconds: 300),
      ));
    }

    return cmds;
  }

  List<VfxCommand> _buildMissCommands(
      BattleAnimationEvent event, Duration offset) {
    return [
      VfxCommand(
        type: VfxType.actorLunge,
        actorId: event.actorId,
        startDelay: offset,
        duration: const Duration(milliseconds: 250),
      ),
      VfxCommand(
        type: VfxType.missText,
        targetId: event.targetId,
        text: 'MISS',
        startDelay: offset + const Duration(milliseconds: 200),
        duration: const Duration(milliseconds: 800),
      ),
    ];
  }

  List<VfxCommand> _buildDefendCommands(
      BattleAnimationEvent event, Duration offset) {
    return [
      VfxCommand(
        type: VfxType.defendShield,
        actorId: event.actorId,
        targetId: event.actorId,
        startDelay: offset,
        duration: const Duration(milliseconds: 500),
      ),
    ];
  }

  List<VfxCommand> _buildDeathCommands(
      BattleAnimationEvent event, Duration offset) {
    return [
      VfxCommand(
        type: VfxType.deathFadeOut,
        targetId: event.actorId,
        startDelay: offset,
        duration: const Duration(milliseconds: 600),
      ),
    ];
  }
}
