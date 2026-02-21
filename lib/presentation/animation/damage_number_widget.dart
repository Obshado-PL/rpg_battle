import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class DamageNumberWidget extends StatefulWidget {
  final int? value;
  final String? text;
  final bool isCritical;
  final bool isHeal;
  final Offset position;
  final VoidCallback onComplete;

  const DamageNumberWidget({
    super.key,
    this.value,
    this.text,
    this.isCritical = false,
    this.isHeal = false,
    required this.position,
    required this.onComplete,
  });

  @override
  State<DamageNumberWidget> createState() => _DamageNumberWidgetState();
}

class _DamageNumberWidgetState extends State<DamageNumberWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetY;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _offsetY = Tween<double>(begin: 0, end: -40).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1, end: 1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 35),
    ]).animate(_controller);

    if (widget.isCritical) {
      _scale = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.5), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.2), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.2), weight: 50),
      ]).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
    } else {
      _scale = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.1), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      ]).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
    }

    _controller.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayText = widget.text ??
        (widget.isHeal
            ? '+${widget.value}'
            : '${widget.value}');

    Color color;
    double fontSize;
    if (widget.text == 'MISS') {
      color = AppTheme.missColor;
      fontSize = 12;
    } else if (widget.isCritical) {
      color = AppTheme.criticalColor;
      fontSize = 20;
    } else if (widget.isHeal) {
      color = AppTheme.healColor;
      fontSize = 14;
    } else {
      color = AppTheme.damageColor;
      fontSize = 14;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.position.dx - 30,
          top: widget.position.dy + _offsetY.value,
          child: Opacity(
            opacity: _opacity.value.clamp(0, 1),
            child: Transform.scale(
              scale: _scale.value,
              child: SizedBox(
                width: 60,
                child: Text(
                  displayText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: color,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                      Shadow(color: Colors.black, blurRadius: 2, offset: Offset(-1, -1)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
