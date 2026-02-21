import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/sound_manager.dart';
import '../../providers/game_providers.dart';

class RpgButton extends ConsumerWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool enabled;
  final double? width;

  const RpgButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color,
    this.enabled = true,
    this.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bgColor = enabled
        ? (color ?? theme.colorScheme.primary)
        : Colors.grey[700]!;

    return SizedBox(
      width: width,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        elevation: enabled ? 4 : 1,
        child: InkWell(
          onTap: enabled
              ? () {
                  ref.read(soundManagerProvider).playSfx(SfxType.uiTap);
                  onTap?.call();
                }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: enabled
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: enabled ? Colors.white : Colors.grey),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: enabled ? Colors.white : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
