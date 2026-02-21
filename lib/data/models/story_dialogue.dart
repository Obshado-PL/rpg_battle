class DialogueLine {
  final String speaker;
  final String text;

  const DialogueLine({required this.speaker, required this.text});

  factory DialogueLine.fromJson(Map<String, dynamic> json) {
    return DialogueLine(
      speaker: json['speaker'] as String,
      text: json['text'] as String,
    );
  }
}

class EncounterStory {
  final String encounterId;
  final List<DialogueLine> preBattle;
  final List<DialogueLine> postBattle;

  const EncounterStory({
    required this.encounterId,
    required this.preBattle,
    this.postBattle = const [],
  });

  factory EncounterStory.fromJson(Map<String, dynamic> json) {
    return EncounterStory(
      encounterId: json['encounterId'] as String,
      preBattle: (json['preBattle'] as List)
          .map((e) => DialogueLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      postBattle: (json['postBattle'] as List?)
              ?.map((e) => DialogueLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
