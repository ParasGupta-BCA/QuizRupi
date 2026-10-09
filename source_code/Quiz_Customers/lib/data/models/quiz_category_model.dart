class QuizCategoryModel {
  final String id;
  final String name;
  final String? iconKey;
  final String? colorHex;
  final String difficulty;
  final int mcqCount;
  final bool isNew;

  QuizCategoryModel({
    required this.id,
    required this.name,
    this.iconKey,
    this.colorHex,
    this.difficulty = 'Medium',
    this.mcqCount = 1000,
    this.isNew = false,
  });

  factory QuizCategoryModel.fromJson(Map<String, dynamic> json) {
    return QuizCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconKey: json['icon_key'] as String?,
      colorHex: json['color_hex'] as String?,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      mcqCount: json['mcq_count'] as int? ?? 1000,
      isNew: json['is_new'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_key': iconKey,
      'color_hex': colorHex,
      'difficulty': difficulty,
      'mcq_count': mcqCount,
      'is_new': isNew,
    };
  }
}
