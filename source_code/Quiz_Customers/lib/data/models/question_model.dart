class QuestionModel {
  final String id;
  final String categoryId;
  final String questionText;
  final String? imageUrl;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption; // 'A', 'B', 'C', 'D'
  final String? explanationText;
  final String difficulty;
  final int timeLimitSeconds;

  QuestionModel({
    required this.id,
    required this.categoryId,
    required this.questionText,
    this.imageUrl,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    this.explanationText,
    this.difficulty = 'Medium',
    this.timeLimitSeconds = 15,
  });

  String getOptionText(String optionKey) {
    switch (optionKey.toUpperCase()) {
      case 'A':
        return optionA;
      case 'B':
        return optionB;
      case 'C':
        return optionC;
      case 'D':
        return optionD;
      default:
        return '';
    }
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      questionText: json['question_text'] as String,
      imageUrl: json['image_url'] as String?,
      optionA: json['option_a'] as String,
      optionB: json['option_b'] as String,
      optionC: json['option_c'] as String,
      optionD: json['option_d'] as String,
      correctOption: json['correct_option'] as String,
      explanationText: json['explanation_text'] as String?,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      timeLimitSeconds: json['time_limit_seconds'] as int? ?? 15,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'question_text': questionText,
      'image_url': imageUrl,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_option': correctOption,
      'explanation_text': explanationText,
      'difficulty': difficulty,
      'time_limit_seconds': timeLimitSeconds,
    };
  }
}
