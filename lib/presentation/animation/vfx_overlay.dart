import 'package:flutter/material.dart';

import 'battle_animation_controller.dart';
import 'damage_number_widget.dart';
import 'skill_effect_widget.dart';

class BattleVfxOverlay extends StatefulWidget {
  final BattleAnimationController animationController;
  final Map<String, GlobalKey> targetKeys;

  const BattleVfxOverlay({
    super.key,
    required this.animationController,
    required this.targetKeys,
  });

  @override
  State<BattleVfxOverlay> createState() => _BattleVfxOverlayState();
}

class _BattleVfxOverlayState extends State<BattleVfxOverlay>
    with SingleTickerProviderStateMixin {
  final Set<String> _activeWidgetIds = {};
  late AnimationController _flashController;
  late Animation<double> _flashOpacity;

  @override
  void initState() {
    super.initState();
    widget.animationController.addListener(_onCommandsChanged);

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0), weight: 60),
    ]).animate(_flashController);
  }

  @override
  void dispose() {
    widget.animationController.removeListener(_onCommandsChanged);
    _flashController.dispose();
    super.dispose();
  }

  void _onCommandsChanged() {
    if (!mounted) return;

    // Trigger screen flash if there's a screenFlash command we haven't handled
    final flashCmds = widget.animationController.activeCommands
        .where((c) => c.type == VfxType.screenFlash);
    for (final cmd in flashCmds) {
      if (!_activeWidgetIds.contains(cmd.id)) {
        _activeWidgetIds.add(cmd.id);
        _flashController.forward(from: 0);
      }
    }

    setState(() {});
  }

  Offset? _getTargetCenter(String? targetId) {
    if (targetId == null) return null;
    final key = widget.targetKeys[targetId];
    if (key == null) return null;
    final renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final overlay = context.findRenderObject() as RenderBox?;
    if (overlay == null) return null;

    final pos = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    return Offset(
      pos.dx + renderBox.size.width / 2,
      pos.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final commands = widget.animationController.activeCommands;
    final overlayWidgets = <Widget>[];

    for (final cmd in commands) {
      if (_activeWidgetIds.contains(cmd.id) &&
          cmd.type != VfxType.screenFlash) {
        continue;
      }

      switch (cmd.type) {
        case VfxType.damageNumber:
          final pos = _getTargetCenter(cmd.targetId);
          if (pos != null) {
            _activeWidgetIds.add(cmd.id);
            overlayWidgets.add(DamageNumberWidget(
              key: ValueKey(cmd.id),
              value: cmd.value,
              isCritical: cmd.isCritical,
              position: pos,
              onComplete: () {
                _activeWidgetIds.remove(cmd.id);
              },
            ));
          }
          break;

        case VfxType.healNumber:
          final pos = _getTargetCenter(cmd.targetId);
          if (pos != null) {
            _activeWidgetIds.add(cmd.id);
            overlayWidgets.add(DamageNumberWidget(
              key: ValueKey(cmd.id),
              value: cmd.value,
              isHeal: true,
              position: pos,
              onComplete: () {
                _activeWidgetIds.remove(cmd.id);
              },
            ));
          }
          break;

        case VfxType.missText:
          final pos = _getTargetCenter(cmd.targetId);
          if (pos != null) {
            _activeWidgetIds.add(cmd.id);
            overlayWidgets.add(DamageNumberWidget(
              key: ValueKey(cmd.id),
              text: 'MISS',
              position: pos,
              onComplete: () {
                _activeWidgetIds.remove(cmd.id);
              },
            ));
          }
          break;

        case VfxType.skillEffect:
          final pos = _getTargetCenter(cmd.targetId);
          if (pos != null) {
            _activeWidgetIds.add(cmd.id);
            overlayWidgets.add(SkillEffectWidget(
              key: ValueKey(cmd.id),
              effectKey: cmd.effectKey ?? 'fire',
              position: pos,
              onComplete: () {
                _activeWidgetIds.remove(cmd.id);
              },
            ));
          }
          break;

        case VfxType.defendShield:
          final pos = _getTargetCenter(cmd.targetId ?? cmd.actorId);
          if (pos != null) {
            _activeWidgetIds.add(cmd.id);
            overlayWidgets.add(SkillEffectWidget(
              key: ValueKey(cmd.id),
              effectKey: 'defend',
              position: pos,
              onComplete: () {
                _activeWidgetIds.remove(cmd.id);
              },
            ));
          }
          break;

        default:
          break;
      }
    }

    return Stack(
      children: [
        // Screen flash overlay
        AnimatedBuilder(
          animation: _flashController,
          builder: (context, child) {
            if (_flashOpacity.value <= 0) return const SizedBox.shrink();
            return Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.white.withValues(alpha: _flashOpacity.value),
                ),
              ),
            );
          },
        ),
        // Floating damage numbers, skill effects, etc.
        ...overlayWidgets,
      ],
    );
  }
}
