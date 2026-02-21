import 'package:flutter/material.dart';

import '../../../data/models/story_dialogue.dart';

class DialogueOverlay extends StatefulWidget {
  final List<DialogueLine> lines;
  final VoidCallback onComplete;

  const DialogueOverlay({
    super.key,
    required this.lines,
    required this.onComplete,
  });

  @override
  State<DialogueOverlay> createState() => _DialogueOverlayState();
}

class _DialogueOverlayState extends State<DialogueOverlay>
    with SingleTickerProviderStateMixin {
  int _currentLine = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _advance() {
    if (_currentLine < widget.lines.length - 1) {
      setState(() => _currentLine++);
      _fadeController.forward(from: 0);
    } else {
      widget.onComplete();
    }
  }

  void _skip() {
    widget.onComplete();
  }

  Color _speakerColor(String speaker) {
    return switch (speaker) {
      'Roland' => Colors.orange,
      'Lyra' => Colors.purple[300]!,
      'Sera' => Colors.green[300]!,
      'Kael' => Colors.amber,
      _ => Colors.white70,
    };
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.lines[_currentLine];

    return Material(
      color: Colors.black87,
      child: GestureDetector(
        onTap: _advance,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  const Spacer(),
                  // Dialogue box at bottom
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _speakerColor(line.speaker)
                              .withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _speakerColor(line.speaker)
                                .withValues(alpha: 0.2),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Speaker name
                          Text(
                            line.speaker,
                            style: TextStyle(
                              color: _speakerColor(line.speaker),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Dialogue text
                          Text(
                            line.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Progress indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_currentLine + 1} / ${widget.lines.length}',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                              const Text(
                                'Tap to continue',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

              // Skip button
              Positioned(
                top: 8,
                right: 16,
                child: TextButton(
                  onPressed: _skip,
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
