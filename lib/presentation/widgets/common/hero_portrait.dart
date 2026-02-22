import 'package:flutter/material.dart';

import '../../../core/utils/hero_sprite_helper.dart';

class HeroPortrait extends StatelessWidget {
  final int spriteId;
  final double size;
  final Color? borderColor;
  final bool isSelected;

  const HeroPortrait({
    super.key,
    required this.spriteId,
    this.size = 40,
    this.borderColor,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (spriteId <= 0) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.person, size: size * 0.6, color: Colors.white38),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: borderColor != null || isSelected
            ? Border.all(
                color: borderColor ?? Colors.cyan,
                width: isSelected ? 2 : 1,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Image.asset(
          HeroSpriteHelper.staticImage(spriteId),
          width: size,
          height: size,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }
}
