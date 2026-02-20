import 'package:flutter/material.dart';

import '../../../data/models/enemy.dart';
import '../common/hp_bar.dart';

class EnemySprite extends StatefulWidget {
  final Enemy enemy;
  final bool isTargeted;
  final bool isSelectable;
  final VoidCallback? onTap;

  const EnemySprite({
    super.key,
    required this.enemy,
    this.isTargeted = false,
    this.isSelectable = false,
    this.onTap,
  });

  @override
  State<EnemySprite> createState() => _EnemySpriteState();
}

class _EnemySpriteState extends State<EnemySprite>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(EnemySprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTargeted && !oldWidget.isTargeted) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isTargeted && oldWidget.isTargeted) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enemy = widget.enemy;
    final spriteColor = Color(int.parse(enemy.spriteColor));

    return GestureDetector(
      onTap: widget.isSelectable ? widget.onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: enemy.isAlive ? 1.0 : 0.3,
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enemy sprite (colored shape with icon)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: spriteColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isTargeted
                        ? Colors.yellow
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
          ),
        ),
      ),
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
