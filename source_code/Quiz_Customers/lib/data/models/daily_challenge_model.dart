class DailyChallengeModel {
  final String id;
  final DateTime date;
  final String categoryId;
  final int bonusCoins;
  final int totalQuestions;
  final List<String> questionIds;

  DailyChallengeModel({
    required this.id,
    required this.date,
    required this.categoryId,
    this.bonusCoins = 50,
    this.totalQuestions = 10,
    required this.questionIds,
  });

  factory DailyChallengeModel.fromJson(Map<String, dynamic> json) {
    List<String> qIds = [];
    if (json['question_ids'] != null) {
      if (json['question_ids'] is List) {
        qIds = (json['question_ids'] as List).map((e) => e.toString()).toList();
      }
    }
    return DailyChallengeModel(
      id: json['id'] as String,
      date: json['date'] != null
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      categoryId: json['category_id'] as String,
      bonusCoins: json['bonus_coins'] as int? ?? 50,
      totalQuestions: json['total_questions'] as int? ?? 10,
      questionIds: qIds,
    );
  }
}

class DailyChallengeProgressModel {
  final String id;
  final String userId;
  final String challengeId;
  final int questionsCompleted;
  final bool completed;

  DailyChallengeProgressModel({
    required this.id,
    required this.userId,
    required this.challengeId,
    this.questionsCompleted = 0,
    this.completed = false,
  });

  factory DailyChallengeProgressModel.fromJson(Map<String, dynamic> json) {
    return DailyChallengeProgressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      challengeId: json['challenge_id'] as String,
      questionsCompleted: json['questions_completed'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }
}
