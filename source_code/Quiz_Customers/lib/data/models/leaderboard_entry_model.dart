class LeaderboardEntryModel {
  final String id;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int pointsEarned;
  final int rank;
  final double accuracy;

  LeaderboardEntryModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.pointsEarned,
    required this.rank,
    this.accuracy = 100.0,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return LeaderboardEntryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: profile?['full_name'] as String? ?? 'Quiz Champ',
      avatarUrl: profile?['avatar_url'] as String?,
      pointsEarned: json['points_earned'] as int? ?? 0,
      rank: json['rank'] as int? ?? 1,
      accuracy: 95.0,
    );
  }
}
