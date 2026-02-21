import 'package:flutter/material.dart';

import '../../../data/models/enemy.dart';
import '../../animation/battle_animation_controller.dart';
import '../common/hp_bar.dart';

class EnemySprite extends StatefulWidget {
  final Enemy enemy;
  final bool isTargeted;
  final bool isSelectable;
  final VoidCallback? onTap;
  final BattleAnimationController? animationController;

  const EnemySprite({
    super.key,
    required this.enemy,
    this.isTargeted = false,
    this.isSelectable = false,
    this.onTap,
    this.animationController,
  });

  @override
  State<EnemySprite> createState() => _EnemySpriteState();
}

class _EnemySpriteState extends State<EnemySprite>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  late AnimationController _lungeController;
  late Animation<double> _lungeAnimation;

  late AnimationController _deathController;
  late Animation<double> _deathScale;
  late Animation<double> _deathOpacity;

  bool _isFlashing = false;
  bool _isDying = false;

  @override
  void initState() {
    super.initState();

    // Targeting pulse
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Hit shake
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 5), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 5, end: -5), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -5, end: 4), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 4, end: -3), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 25),
    ]).animate(_shakeController);

    // Actor lunge (moves down toward heroes)
    _lungeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _lungeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 12), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 12, end: 0), weight: 60),
    ]).animate(
      CurvedAnimation(parent: _lungeController, curve: Curves.easeOut),
    );

    // Death fade + shrink
    _deathController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _deathScale = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _deathController, curve: Curves.easeIn),
    );
    _deathOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _deathController, curve: Curves.easeIn),
    );

    widget.animationController?.addListener(_onAnimationUpdate);
  }

  @override
  void didUpdateWidget(EnemySprite oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Targeting pulse
    if (widget.isTargeted && !oldWidget.isTargeted) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isTargeted && oldWidget.isTargeted) {
      _pulseController.stop();
      _pulseController.reset();
    }

    // Swap listener if controller changed
    if (widget.animationController != oldWidget.animationController) {
      oldWidget.animationController?.removeListener(_onAnimationUpdate);
      widget.animationController?.addListener(_onAnimationUpdate);
    }
  }

  void _onAnimationUpdate() {
    if (!mounted) return;
    final ctrl = widget.animationController!;
    final enemyId = widget.enemy.id;

    // Hit flash
    final hasFlash = ctrl.hasCommandForTarget(enemyId, VfxType.targetHitFlash);
    if (hasFlash && !_isFlashing) {
      setState(() => _isFlashing = true);
    } else if (!hasFlash && _isFlashing) {
      setState(() => _isFlashing = false);
    }

    // Shake
    if (ctrl.hasCommandForTarget(enemyId, VfxType.targetShake) &&
        !_shakeController.isAnimating) {
      _shakeController.forward(from: 0);
    }

    // Lunge (this enemy is the actor)
    if (ctrl.hasCommandForActor(enemyId, VfxType.actorLunge) &&
        !_lungeController.isAnimating) {
      _lungeController.forward(from: 0);
    }

    // Death
    if (ctrl.hasCommandForTarget(enemyId, VfxType.deathFadeOut) && !_isDying) {
      _isDying = true;
      _deathController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.animationController?.removeListener(_onAnimationUpdate);
    _pulseController.dispose();
    _shakeController.dispose();
    _lungeController.dispose();
    _deathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enemy = widget.enemy;
    final spriteColor = Color(int.parse(enemy.spriteColor));

    return GestureDetector(
      onTap: widget.isSelectable ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _shakeAnimation,
          _lungeAnimation,
          _deathScale,
          _deathOpacity,
        ]),
        builder: (context, child) {
          final effectiveOpacity = _isDying
              ? _deathOpacity.value.clamp(0.0, 1.0)
              : (enemy.isAlive ? 1.0 : 0.3);
          final effectiveScale = _isDying ? _deathScale.value : 1.0;

          return Opacity(
            opacity: effectiveOpacity,
            child: Transform.translate(
              offset: Offset(_shakeAnimation.value, _lungeAnimation.value),
              child: Transform.scale(
                scale: effectiveScale,
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: _buildContent(context, enemy, spriteColor),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Enemy enemy, Color spriteColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Enemy sprite (colored shape with icon)
        AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _isFlashing
                ? Colors.red.withValues(alpha: 0.9)
                : spriteColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isTargeted
                  ? Colors.yellow
                  : _isFlashing
                      ? Colors.red
                      : widget.isSelectable
                          ? Colors.white38
                          : Colors.transparent,
              width: widget.isTargeted ? 2 : 1,
            ),
            boxShadow: [
              if (widget.isTargeted)
                BoxShadow(
                  color: Colors.yellow.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              if (_isFlashing)
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.6),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              BoxShadow(
                color: spriteColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: _getEnemyIcon(enemy),
          ),
        ),
        const SizedBox(height: 4),
        // Name
        Text(
          enemy.name,
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // HP bar
        SizedBox(
          width: 60,
          child: HpBar(percent: enemy.hpPercent, height: 4),
        ),
      ],
    );
  }

  Widget _getEnemyIcon(Enemy enemy) {
    IconData iconData;
    switch (enemy.behavior) {
      case AiBehavior.boss:
        iconData = Icons.whatshot;
        break;
      case AiBehavior.aggressive:
        iconData = Icons.dangerous;
        break;
      case AiBehavior.defensive:
        iconData = Icons.shield;
        break;
      case AiBehavior.random:
        iconData = Icons.pest_control;
        break;
    }
    return Icon(iconData, color: Colors.white, size: 28);
  }
}
