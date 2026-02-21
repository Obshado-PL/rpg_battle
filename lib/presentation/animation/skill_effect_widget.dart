import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SkillEffectWidget extends StatefulWidget {
  final String effectKey;
  final Offset position;
  final VoidCallback onComplete;

  const SkillEffectWidget({
    super.key,
    required this.effectKey,
    required this.position,
    required this.onComplete,
  });

  @override
  State<SkillEffectWidget> createState() => _SkillEffectWidgetState();
}

class _SkillEffectWidgetState extends State<SkillEffectWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _particleSpread;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6), weight: 40),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1, end: 1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 40),
    ]).animate(_controller);

    _particleSpread = Tween<double>(begin: 0, end: 24).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    final isPhysical = _effectConfig.isPhysical;
    _rotation = Tween<double>(begin: 0, end: isPhysical ? 0.5 : 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _EffectConfig get _effectConfig => _getConfig(widget.effectKey);

  static _EffectConfig _getConfig(String effectKey) {
    switch (effectKey) {
      case 'fire':
        return _EffectConfig(
          icon: Icons.local_fire_department,
          color: AppTheme.fireColor,
          glowColor: Colors.orange,
          isPhysical: false,
        );
      case 'ice':
        return _EffectConfig(
          icon: Icons.ac_unit,
          color: AppTheme.iceColor,
          glowColor: Colors.cyan,
          isPhysical: false,
        );
      case 'slash':
      case 'power_slash':
        return _EffectConfig(
          icon: Icons.flash_on,
          color: AppTheme.physicalColor,
          glowColor: Colors.white,
          isPhysical: true,
        );
      case 'backstab':
        return _EffectConfig(
          icon: Icons.flash_on,
          color: AppTheme.physicalColor,
          glowColor: Colors.amber,
          isPhysical: true,
        );
      case 'dart':
        return _EffectConfig(
          icon: Icons.gps_fixed,
          color: AppTheme.poisonColor,
          glowColor: Colors.purple,
          isPhysical: true,
        );
      case 'heal':
        return _EffectConfig(
          icon: Icons.favorite,
          color: AppTheme.healColor,
          glowColor: Colors.greenAccent,
          isPhysical: false,
        );
      case 'revive':
        return _EffectConfig(
          icon: Icons.auto_awesome,
          color: AppTheme.criticalColor,
          glowColor: Colors.yellowAccent,
          isPhysical: false,
        );
      case 'lightning':
        return _EffectConfig(
          icon: Icons.bolt,
          color: Colors.yellow,
          glowColor: Colors.amber,
          isPhysical: false,
        );
      case 'dark':
        return _EffectConfig(
          icon: Icons.nightlight_round,
          color: Colors.deepPurple,
          glowColor: Colors.purple,
          isPhysical: false,
        );
      case 'drain':
        return _EffectConfig(
          icon: Icons.water_drop,
          color: Colors.red[900]!,
          glowColor: Colors.redAccent,
          isPhysical: false,
        );
      case 'defend':
        return _EffectConfig(
          icon: Icons.shield,
          color: AppTheme.shieldColor,
          glowColor: Colors.blueAccent,
          isPhysical: false,
        );
      default:
        return _EffectConfig(
          icon: Icons.star,
          color: Colors.white,
          glowColor: Colors.white54,
          isPhysical: false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _effectConfig;
    final particleAngles = List.generate(6, (i) => i * (pi * 2 / 6));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.position.dx - 30,
          top: widget.position.dy - 30,
          child: Opacity(
            opacity: _opacity.value.clamp(0, 1),
            child: SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Glow circle
                  Center(
                    child: Transform.scale(
                      scale: _scale.value,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              config.color.withValues(alpha: 0.8),
                              config.glowColor.withValues(alpha: 0.3),
                              config.glowColor.withValues(alpha: 0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: config.color.withValues(alpha: 0.6),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Center icon
                  Center(
                    child: Transform.scale(
                      scale: _scale.value,
                      child: Transform.rotate(
                        angle: _rotation.value,
                        child: Icon(
                          config.icon,
                          size: 24,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: config.color,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Particles
                  ...particleAngles.map((angle) {
                    final dx = cos(angle) * _particleSpread.value;
                    final dy = sin(angle) * _particleSpread.value;
                    return Positioned(
                      left: 30 + dx - 3,
                      top: 30 + dy - 3,
                      child: Opacity(
                        opacity: (1 - _controller.value).clamp(0, 1),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: config.color,
                            boxShadow: [
                              BoxShadow(
                                color: config.glowColor,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EffectConfig {
  final IconData icon;
  final Color color;
  final Color glowColor;
  final bool isPhysical;

  const _EffectConfig({
    required this.icon,
    required this.color,
    required this.glowColor,
    required this.isPhysical,
  });
}
