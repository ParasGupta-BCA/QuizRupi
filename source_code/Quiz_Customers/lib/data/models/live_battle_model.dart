class LiveBattleModel {
  final String id;
  final String player1Id;
  final String? player2Id;
  final String categoryId;
  final String status; // 'waiting', 'live', 'completed'
  final int player1Score;
  final int player2Score;
  final String? winnerId;
  final int currentQuestionIndex;
  final List<dynamic> questions;
  final DateTime createdAt;

  LiveBattleModel({
    required this.id,
    required this.player1Id,
    this.player2Id,
    required this.categoryId,
    this.status = 'waiting',
    this.player1Score = 0,
    this.player2Score = 0,
    this.winnerId,
    this.currentQuestionIndex = 0,
    required this.questions,
    required this.createdAt,
  });

  factory LiveBattleModel.fromJson(Map<String, dynamic> json) {
    return LiveBattleModel(
      id: json['id'] as String,
      player1Id: json['player1_id'] as String,
      player2Id: json['player2_id'] as String?,
      categoryId: json['category_id'] as String,
      status: json['status'] as String? ?? 'waiting',
      player1Score: json['player1_score'] as int? ?? 0,
      player2Score: json['player2_score'] as int? ?? 0,
      winnerId: json['winner_id'] as String?,
      currentQuestionIndex: json['current_question_index'] as int? ?? 0,
      questions: json['questions'] is List ? json['questions'] as List : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'category_id': categoryId,
      'status': status,
      'player1_score': player1Score,
      'player2_score': player2Score,
      'winner_id': winnerId,
      'current_question_index': currentQuestionIndex,
      'questions': questions,
    };
  }
}
