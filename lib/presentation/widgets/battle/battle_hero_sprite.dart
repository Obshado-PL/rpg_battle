import 'package:flutter/material.dart';

import '../../../data/models/character.dart';
import '../../../data/models/stats.dart';
import '../../../data/models/status_effect.dart';
import '../../animation/battle_animation_controller.dart';
import '../common/animated_hero_sprite.dart';
import '../common/hp_bar.dart';

class BattleHeroSprite extends StatefulWidget {
  final Character hero;
  final bool isActive;
  final bool isSelectable;
  final VoidCallback? onTap;
  final BattleAnimationController? animationController;
  final Stats? effectiveStats;

  const BattleHeroSprite({
    super.key,
    required this.hero,
    this.isActive = false,
    this.isSelectable = false,
    this.onTap,
    this.animationController,
    this.effectiveStats,
  });

  @override
  State<BattleHeroSprite> createState() => _BattleHeroSpriteState();
}

class _BattleHeroSpriteState extends State<BattleHeroSprite>
    with TickerProviderStateMixin {
  // Targeting pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Hit shake
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Actor lunge (toward enemies on the right)
  late AnimationController _lungeController;
  late Animation<double> _lungeAnimation;

  // Death fade + shrink
  late AnimationController _deathController;
  late Animation<double> _deathScale;
  late Animation<double> _deathOpacity;

  bool _isFlashing = false;
  bool _isDying = false;
  SpriteAnimation _spriteState = SpriteAnimation.idle;

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

    // Actor lunge (positive X — toward enemies on the right)
    _lungeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _lungeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 16), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 16, end: 0), weight: 60),
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
  void didUpdateWidget(BattleHeroSprite oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Targeting pulse
    if (widget.isSelectable && !oldWidget.isSelectable) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isSelectable && oldWidget.isSelectable) {
      _pulseController.stop();
      _pulseController.reset();
    }

    if (widget.animationController != oldWidget.animationController) {
      oldWidget.animationController?.removeListener(_onAnimationUpdate);
      widget.animationController?.addListener(_onAnimationUpdate);
    }
  }

  void _onAnimationUpdate() {
    if (!mounted) return;
    final ctrl = widget.animationController!;
    final heroId = widget.hero.id;

    // Hit flash (hero is target of enemy attack)
    final hasFlash = ctrl.hasCommandForTarget(heroId, VfxType.targetHitFlash);
    if (hasFlash && !_isFlashing) {
      setState(() => _isFlashing = true);
    } else if (!hasFlash && _isFlashing) {
      setState(() => _isFlashing = false);
    }

    // Shake (hero is target)
    if (ctrl.hasCommandForTarget(heroId, VfxType.targetShake) &&
        !_shakeController.isAnimating) {
      _shakeController.forward(from: 0);
    }

    // Lunge + attack animation (hero is actor)
    if (ctrl.hasCommandForActor(heroId, VfxType.actorLunge) &&
        !_lungeController.isAnimating) {
      _lungeController.forward(from: 0);
      setState(() => _spriteState = SpriteAnimation.attack);
    }

    // Death
    if (ctrl.hasCommandForTarget(heroId, VfxType.deathFadeOut) && !_isDying) {
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
    final hero = widget.hero;
    final stats = widget.effectiveStats ?? hero.baseStats;
    final hpPct = stats.maxHp > 0 ? hero.currentHp / stats.maxHp : 0.0;

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
              : (hero.isAlive ? 1.0 : 0.3);
          final effectiveScale = _isDying ? _deathScale.value : 1.0;

          return Opacity(
            opacity: effectiveOpacity,
            child: Transform.translate(
              offset: Offset(
                _lungeAnimation.value + _shakeAnimation.value,
                0,
              ),
              child: Transform.scale(
                scale: effectiveScale,
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: _buildContent(context, hero, hpPct),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Character hero, double hpPct) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Active turn indicator
        if (widget.isActive)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: const BoxDecoration(
              color: Colors.yellow,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow,
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        // Animated sprite with flash overlay
        Stack(
          children: [
            AnimatedHeroSprite(
              spriteId: hero.spriteId,
              animation: _spriteState,
              size: 72,
              onAttackComplete: () {
                if (mounted) {
                  setState(() => _spriteState = SpriteAnimation.idle);
                }
              },
            ),
            // Red hit flash overlay
            if (_isFlashing)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            // Active glow border
            if (widget.isActive)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.yellow.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            // Selectable glow
            if (widget.isSelectable && !widget.isActive)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        // Name
        SizedBox(
          width: 72,
          child: Text(
            hero.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 8,
                  color: hero.isAlive ? Colors.white : Colors.grey,
                ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        // HP bar
        SizedBox(
          width: 72,
          child: HpBar(percent: hpPct, height: 4),
        ),
        // Status effects
        if (hero.statusEffects.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Wrap(
              spacing: 1,
              children: hero.statusEffects.map((e) {
                final (icon, color) = _statusIcon(e.type);
                return Icon(icon, size: 8, color: color);
              }).toList(),
            ),
          ),
      ],
    );
  }

  static (IconData, Color) _statusIcon(StatusEffectType type) {
    return switch (type) {
      StatusEffectType.poison => (Icons.science, Colors.green),
      StatusEffectType.burn => (Icons.local_fire_department, Colors.orange),
      StatusEffectType.stun => (Icons.flash_on, Colors.yellow),
      StatusEffectType.atkUp => (Icons.arrow_upward, Colors.red),
      StatusEffectType.atkDown => (Icons.arrow_downward, Colors.red),
      StatusEffectType.defUp => (Icons.arrow_upward, Colors.blue),
      StatusEffectType.defDown => (Icons.arrow_downward, Colors.blue),
    };
  }
}
