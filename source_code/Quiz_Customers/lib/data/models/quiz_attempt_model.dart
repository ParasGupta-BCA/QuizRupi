class QuizAttemptModel {
  final String id;
  final String userId;
  final String categoryId;
  final String mode;
  final int score;
  final int correctCount;
  final int totalQuestions;
  final int coinsEarned;
  final int xpEarned;
  final DateTime startedAt;
  final DateTime? completedAt;

  int get timeTakenSeconds {
    if (completedAt != null) {
      final diff = completedAt!.difference(startedAt).inSeconds;
      return diff > 0 ? diff : 35;
    }
    return 45;
  }

  QuizAttemptModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    this.mode = 'solo',
    this.score = 0,
    this.correctCount = 0,
    this.totalQuestions = 10,
    this.coinsEarned = 0,
    this.xpEarned = 0,
    required this.startedAt,
    this.completedAt,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      mode: json['mode'] as String? ?? 'solo',
      score: json['score'] as int? ?? 0,
      correctCount: json['correct_count'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 10,
      coinsEarned: json['coins_earned'] as int? ?? 0,
      xpEarned: json['xp_earned'] as int? ?? 0,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'mode': mode,
      'score': score,
      'correct_count': correctCount,
      'total_questions': totalQuestions,
      'coins_earned': coinsEarned,
      'xp_earned': xpEarned,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
