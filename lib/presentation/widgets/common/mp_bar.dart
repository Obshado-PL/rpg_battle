import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class MpBar extends StatelessWidget {
  final double percent;
  final double height;
  final bool showLabel;
  final int? current;
  final int? max;

  const MpBar({
    super.key,
    required this.percent,
    this.height = 6,
    this.showLabel = false,
    this.current,
    this.max,
  });

  @override
  Widget build(BuildContext context) {
    final clampedPercent = percent.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel && current != null && max != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'MP $current/$max',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Container(color: Colors.grey[800]),
                FractionallySizedBox(
                  widthFactor: clampedPercent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.mpBarBlue,
                          AppTheme.mpBarBlue.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
