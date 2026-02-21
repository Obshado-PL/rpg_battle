import 'package:flutter/material.dart';

import '../../../data/models/character.dart';
import '../../../data/models/stats.dart';
import '../../animation/battle_animation_controller.dart';
import '../common/hp_bar.dart';
import '../common/mp_bar.dart';

class HeroStatusCard extends StatefulWidget {
  final Character hero;
  final bool isActive;
  final bool isSelectable;
  final VoidCallback? onTap;
  final BattleAnimationController? animationController;
  final Stats? effectiveStats;

  const HeroStatusCard({
    super.key,
    required this.hero,
    this.isActive = false,
    this.isSelectable = false,
    this.onTap,
    this.animationController,
    this.effectiveStats,
  });

  @override
  State<HeroStatusCard> createState() => _HeroStatusCardState();
}

class _HeroStatusCardState extends State<HeroStatusCard>
    with TickerProviderStateMixin {
  late AnimationController _hitFlashController;
  late Animation<Color?> _hitFlashColor;

  late AnimationController _healGlowController;
  late Animation<Color?> _healGlowColor;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  bool _isFlashing = false;
  bool _isHealing = false;

  @override
  void initState() {
    super.initState();

    // Hit flash (red border pulse)
    _hitFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _hitFlashColor = ColorTween(
      begin: Colors.transparent,
      end: Colors.red.withValues(alpha: 0.6),
    ).animate(CurvedAnimation(
      parent: _hitFlashController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));
    _hitFlashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _hitFlashController.reverse();
      }
    });

    // Heal glow (green border pulse)
    _healGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _healGlowColor = ColorTween(
      begin: Colors.transparent,
      end: Colors.greenAccent.withValues(alpha: 0.6),
    ).animate(CurvedAnimation(
      parent: _healGlowController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));
    _healGlowController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _healGlowController.reverse();
      }
    });

    // Hit shake
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 4), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 4, end: -4), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -4, end: 3), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 3, end: -2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -2, end: 0), weight: 25),
    ]).animate(_shakeController);

    widget.animationController?.addListener(_onAnimationUpdate);
  }

  @override
  void didUpdateWidget(HeroStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationController != oldWidget.animationController) {
      oldWidget.animationController?.removeListener(_onAnimationUpdate);
      widget.animationController?.addListener(_onAnimationUpdate);
    }
  }

  void _onAnimationUpdate() {
    if (!mounted) return;
    final ctrl = widget.animationController!;
    final heroId = widget.hero.id;

    // Hit flash
    final hasFlash = ctrl.hasCommandForTarget(heroId, VfxType.targetHitFlash);
    if (hasFlash && !_isFlashing) {
      _isFlashing = true;
      _hitFlashController.forward(from: 0);
    } else if (!hasFlash && _isFlashing) {
      _isFlashing = false;
    }

    // Shake
    if (ctrl.hasCommandForTarget(heroId, VfxType.targetShake) &&
        !_shakeController.isAnimating) {
      _shakeController.forward(from: 0);
    }

    // Heal glow
    final hasHeal = ctrl.activeCommands.any((c) =>
        c.targetId == heroId &&
        (c.type == VfxType.healNumber || c.type == VfxType.skillEffect));
    if (hasHeal && !_isHealing) {
      _isHealing = true;
      _healGlowController.forward(from: 0);
    } else if (!hasHeal && _isHealing) {
      _isHealing = false;
    }
  }

  @override
  void dispose() {
    widget.animationController?.removeListener(_onAnimationUpdate);
    _hitFlashController.dispose();
    _healGlowController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hero = widget.hero;
    final stats = widget.effectiveStats ?? hero.baseStats;
    final hpPct = stats.maxHp > 0 ? hero.currentHp / stats.maxHp : 0.0;
    final mpPct = stats.maxMp > 0 ? hero.currentMp / stats.maxMp : 0.0;

    return GestureDetector(
      onTap: widget.isSelectable ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _hitFlashColor,
          _healGlowColor,
          _shakeAnimation,
        ]),
        builder: (context, child) {
          // Determine border/glow color from animations
          Color borderColor;
          List<BoxShadow> shadows = [];

          if (_hitFlashColor.value != null &&
              _hitFlashColor.value != Colors.transparent) {
            borderColor = _hitFlashColor.value!;
            shadows.add(BoxShadow(
              color: Colors.red.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ));
          } else if (_healGlowColor.value != null &&
              _healGlowColor.value != Colors.transparent) {
            borderColor = _healGlowColor.value!;
            shadows.add(BoxShadow(
              color: Colors.green.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ));
          } else if (widget.isActive) {
            borderColor = theme.colorScheme.primary;
          } else if (widget.isSelectable) {
            borderColor = Colors.green.withValues(alpha: 0.5);
          } else {
            borderColor = Colors.white.withValues(alpha: 0.1);
          }

          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hero.isAlive
                    ? (widget.isActive
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05))
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: widget.isActive ? 2 : 1,
                ),
                boxShadow: shadows,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _classIcon(),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hero.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hero.isAlive ? Colors.white : Colors.grey,
                            fontWeight:
                                widget.isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hero.isDefending)
                        const Icon(Icons.shield, size: 12, color: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 4),
                  HpBar(percent: hpPct, height: 6),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Text(
                        '${hero.currentHp}/${stats.maxHp}',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  MpBar(percent: mpPct, height: 4),
                  Row(
                    children: [
                      Text(
                        '${hero.currentMp}/${stats.maxMp}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 7,
                          color: Colors.lightBlueAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _classIcon() {
    IconData iconData;
    Color iconColor;
    switch (widget.hero.heroClass) {
      case HeroClass.warrior:
        iconData = Icons.security;
        iconColor = Colors.orange;
        break;
      case HeroClass.mage:
        iconData = Icons.auto_fix_high;
        iconColor = Colors.purple;
        break;
      case HeroClass.healer:
        iconData = Icons.favorite;
        iconColor = Colors.green;
        break;
      case HeroClass.rogue:
        iconData = Icons.flash_on;
        iconColor = Colors.amber;
        break;
    }
    return Icon(iconData, size: 12, color: iconColor);
  }
}
