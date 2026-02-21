import 'package:flutter/material.dart';

import '../../../data/models/encounter.dart';
import 'map_node.dart';
import 'map_path_painter.dart';

class WorldMapWidget extends StatelessWidget {
  final List<Encounter> encounters;
  final Set<String> clearedEncounters;
  final void Function(Encounter encounter) onEncounterTap;

  const WorldMapWidget({
    super.key,
    required this.encounters,
    required this.clearedEncounters,
    required this.onEncounterTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final nodeSize = 36.0;
        final labelHeight = 20.0;
        final totalNodeHeight = nodeSize + 4 + labelHeight;

        // Calculate map content height (from min to max mapY)
        // Add padding so nodes at edges aren't clipped
        final padding = totalNodeHeight;
        final mapHeight =
            (height - padding * 2).clamp(200.0, double.infinity);

        // Calculate node positions
        final nodePositions = <Offset>[];
        for (final encounter in encounters) {
          final x = padding / 2 + encounter.mapX * (width - padding);
          final y = padding + encounter.mapY * mapHeight;
          nodePositions.add(Offset(x, y));
        }

        // Determine cleared indices for path coloring
        final clearedIndices = <int>{};
        for (var i = 0; i < encounters.length; i++) {
          if (clearedEncounters.contains(encounters[i].id)) {
            clearedIndices.add(i);
          }
        }

        return InteractiveViewer(
          minScale: 0.8,
          maxScale: 2.0,
          constrained: true,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Path lines
                CustomPaint(
                  size: Size(width, height),
                  painter: MapPathPainter(
                    nodePositions: nodePositions,
                    clearedIndices: clearedIndices,
                  ),
                ),

                // Encounter nodes
                for (var i = 0; i < encounters.length; i++)
                  _buildNode(i, nodePositions[i], clearedIndices),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNode(int index, Offset position, Set<int> clearedIndices) {
    final encounter = encounters[index];
    final isCleared = clearedEncounters.contains(encounter.id);
    final prevCleared = index == 0 ||
        clearedEncounters.contains(encounters[index - 1].id);
    final isAvailable = (prevCleared || isCleared) && !isCleared;

    final nodeState = isCleared
        ? MapNodeState.cleared
        : isAvailable
            ? MapNodeState.available
            : !isCleared && prevCleared
                ? MapNodeState.available
                : MapNodeState.locked;

    return Positioned(
      left: position.dx - 40,
      top: position.dy - 18,
      width: 80,
      child: MapNode(
        encounter: encounter,
        nodeState: nodeState,
        index: index,
        onTap: () => onEncounterTap(encounter),
      ),
    );
  }
}
