enum StatusEffectType { poison, burn, stun, atkUp, atkDown, defUp, defDown }

class StatusEffect {
  final StatusEffectType type;
  final int duration;
  final int value;
  final String sourceId;

  const StatusEffect({
    required this.type,
    required this.duration,
    required this.value,
    required this.sourceId,
  });

  StatusEffect copyWith({int? duration, int? value}) {
    return StatusEffect(
      type: type,
      duration: duration ?? this.duration,
      value: value ?? this.value,
      sourceId: sourceId,
    );
  }

  bool get isExpired => duration <= 0;
  bool get isBuff =>
      type == StatusEffectType.atkUp || type == StatusEffectType.defUp;
  bool get isDebuff =>
      type == StatusEffectType.atkDown || type == StatusEffectType.defDown;
  bool get isDot =>
      type == StatusEffectType.poison || type == StatusEffectType.burn;
  bool get isStun => type == StatusEffectType.stun;

  String get displayName => switch (type) {
        StatusEffectType.poison => 'Poison',
        StatusEffectType.burn => 'Burn',
        StatusEffectType.stun => 'Stun',
        StatusEffectType.atkUp => 'ATK Up',
        StatusEffectType.atkDown => 'ATK Down',
        StatusEffectType.defUp => 'DEF Up',
        StatusEffectType.defDown => 'DEF Down',
      };
}
