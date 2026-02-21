class LootDrop {
  final String itemId;
  final bool isEquipment;
  final double dropChance;
  final int minQuantity;
  final int maxQuantity;

  const LootDrop({
    required this.itemId,
    this.isEquipment = false,
    required this.dropChance,
    this.minQuantity = 1,
    this.maxQuantity = 1,
  });

  factory LootDrop.fromJson(Map<String, dynamic> json) {
    return LootDrop(
      itemId: json['itemId'] as String,
      isEquipment: json['isEquipment'] as bool? ?? false,
      dropChance: (json['dropChance'] as num).toDouble(),
      minQuantity: json['minQuantity'] as int? ?? 1,
      maxQuantity: json['maxQuantity'] as int? ?? 1,
    );
  }
}
