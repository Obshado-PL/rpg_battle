import 'package:flutter/material.dart';

import '../../../data/models/encounter.dart';

enum MapNodeState { cleared, available, locked }

class MapNode extends StatelessWidget {
  final Encounter encounter;
  final MapNodeState nodeState;
  final int index;
  final VoidCallback? onTap;

  const MapNode({
    super.key,
    required this.encounter,
    required this.nodeState,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(encounter.backgroundGradientStart));

    return GestureDetector(
      onTap: nodeState != MapNodeState.locked ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Node circle
          _NodeCircle(
            nodeState: nodeState,
            color: color,
            index: index,
          ),
          const SizedBox(height: 4),
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              encounter.name,
              style: TextStyle(
                color: nodeState == MapNodeState.locked
                    ? Colors.grey[600]
                    : Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeCircle extends StatefulWidget {
  final MapNodeState nodeState;
  final Color color;
  final int index;

  const _NodeCircle({
    required this.nodeState,
    required this.color,
    required this.index,
  });

  @override
  State<_NodeCircle> createState() => _NodeCircleState();
}

class _NodeCircleState extends State<_NodeCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.nodeState == MapNodeState.available) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _NodeCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.nodeState == MapNodeState.available) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCleared = widget.nodeState == MapNodeState.cleared;
    final isLocked = widget.nodeState == MapNodeState.locked;
    final isAvailable = widget.nodeState == MapNodeState.available;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isAvailable ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCleared
              ? Colors.green
              : isLocked
                  ? Colors.grey[800]
                  : widget.color,
          border: Border.all(
            color: isCleared
                ? Colors.greenAccent
                : isAvailable
                    ? Colors.amber
                    : Colors.grey[700]!,
            width: isAvailable ? 2.5 : 1.5,
          ),
          boxShadow: isAvailable
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : isCleared
                  ? [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
        ),
        child: Center(
          child: isCleared
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : isLocked
                  ? const Icon(Icons.lock, size: 14, color: Colors.grey)
                  : Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
        ),
      ),
    );
  }
}
