import 'package:flutter/material.dart';

import '../../../core/utils/hero_sprite_helper.dart';

enum SpriteAnimation { idle, attack, walk }

class AnimatedHeroSprite extends StatefulWidget {
  final int spriteId;
  final SpriteAnimation animation;
  final double size;
  final VoidCallback? onAttackComplete;

  const AnimatedHeroSprite({
    super.key,
    required this.spriteId,
    this.animation = SpriteAnimation.idle,
    this.size = 64,
    this.onAttackComplete,
  });

  @override
  State<AnimatedHeroSprite> createState() => _AnimatedHeroSpriteState();
}

class _AnimatedHeroSpriteState extends State<AnimatedHeroSprite>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentFrame = 0;
  SpriteAnimation _activeAnimation = SpriteAnimation.idle;
  late List<String> _frames;

  @override
  void initState() {
    super.initState();
    _activeAnimation = widget.animation;
    _frames = _framesForAnimation(_activeAnimation);
    _controller = AnimationController(
      vsync: this,
      duration: _durationForAnimation(_activeAnimation),
    );
    _controller.addListener(_onTick);
    _controller.repeat();
  }

  @override
  void didUpdateWidget(AnimatedHeroSprite oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.spriteId != oldWidget.spriteId) {
      _frames = _framesForAnimation(_activeAnimation);
      _currentFrame = 0;
    }

    if (widget.animation != oldWidget.animation &&
        widget.animation != _activeAnimation) {
      _switchAnimation(widget.animation);
    }
  }

  void _switchAnimation(SpriteAnimation anim) {
    _activeAnimation = anim;
    _frames = _framesForAnimation(anim);
    _currentFrame = 0;
    _controller.duration = _durationForAnimation(anim);

    if (anim == SpriteAnimation.attack) {
      // Play once then return to idle
      _controller.forward(from: 0);
    } else {
      _controller.repeat();
    }
  }

  void _onTick() {
    final progress = _controller.value;
    final frameIndex = (progress * _frames.length).floor().clamp(0, _frames.length - 1);

    if (frameIndex != _currentFrame) {
      setState(() => _currentFrame = frameIndex);
    }

    // When attack animation finishes, switch back to idle
    if (_activeAnimation == SpriteAnimation.attack &&
        _controller.isCompleted) {
      widget.onAttackComplete?.call();
      _switchAnimation(SpriteAnimation.idle);
    }
  }

  Duration _durationForAnimation(SpriteAnimation anim) {
    return switch (anim) {
      SpriteAnimation.idle => const Duration(milliseconds: 800),
      SpriteAnimation.attack => const Duration(milliseconds: 600),
      SpriteAnimation.walk => const Duration(milliseconds: 720),
    };
  }

  List<String> _framesForAnimation(SpriteAnimation anim) {
    if (widget.spriteId <= 0) return [];
    return switch (anim) {
      SpriteAnimation.idle => HeroSpriteHelper.idleFrames(widget.spriteId),
      SpriteAnimation.attack => HeroSpriteHelper.attackFrames(widget.spriteId),
      SpriteAnimation.walk => HeroSpriteHelper.walkFrames(widget.spriteId),
    };
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_frames.isEmpty || widget.spriteId <= 0) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    return Image.asset(
      _frames[_currentFrame],
      width: widget.size,
      height: widget.size,
      filterQuality: FilterQuality.none,
      gaplessPlayback: true,
    );
  }
}
