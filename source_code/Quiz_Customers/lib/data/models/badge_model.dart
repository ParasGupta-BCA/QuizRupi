class BadgeModel {
  final String id;
  final String name;
  final String? description;
  final String? iconKey;
  final String? criteria;
  final String tier;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  String get title => name;

  BadgeModel({
    required this.id,
    required this.name,
    this.description,
    this.iconKey,
    this.criteria,
    this.tier = 'Gold',
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json, {bool isUnlocked = false, DateTime? unlockedAt}) {
    return BadgeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconKey: json['icon_key'] as String?,
      criteria: json['criteria'] as String?,
      tier: json['tier'] as String? ?? 'Gold',
      isUnlocked: isUnlocked,
      unlockedAt: unlockedAt,
    );
  }
}
