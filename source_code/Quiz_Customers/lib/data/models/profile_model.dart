class ProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String username;
  final String userCode;
  final int level;
  final int xp;
  final int coinsBalance;
  final int currentStreak;
  final int bestStreak;
  final int quizzesPlayed;
  final int correctAnswers;
  final int totalAnswers;
  final String? referralCode;
  final String? referredBy;
  final int stateRank;
  final bool dailyReminder;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.username,
    required this.userCode,
    this.level = 1,
    this.xp = 0,
    this.coinsBalance = 250,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.quizzesPlayed = 0,
    this.correctAnswers = 0,
    this.totalAnswers = 0,
    this.referralCode,
    this.referredBy,
    this.stateRank = 142,
    this.dailyReminder = true,
    required this.createdAt,
  });

  double get accuracyRate {
    if (totalAnswers == 0) return 0.0;
    return (correctAnswers / totalAnswers) * 100;
  }

  double get winAccuracy => accuracyRate;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Quizzer',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      username: json['username'] as String? ?? 'user',
      userCode: json['user_code'] as String? ?? 'QZ-00000',
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      coinsBalance: json['coins_balance'] as int? ?? 250,
      currentStreak: json['current_streak'] as int? ?? 0,
      bestStreak: json['best_streak'] as int? ?? 0,
      quizzesPlayed: json['quizzes_played'] as int? ?? 0,
      correctAnswers: json['correct_answers'] as int? ?? 0,
      totalAnswers: json['total_answers'] as int? ?? 0,
      referralCode: json['referral_code'] as String?,
      referredBy: json['referred_by'] as String?,
      stateRank: json['state_rank'] as int? ?? 142,
      dailyReminder: json['daily_reminder'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'username': username,
      'user_code': userCode,
      'level': level,
      'xp': xp,
      'coins_balance': coinsBalance,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'quizzes_played': quizzesPlayed,
      'correct_answers': correctAnswers,
      'total_answers': totalAnswers,
      'referral_code': referralCode,
      'referred_by': referredBy,
      'state_rank': stateRank,
      'daily_reminder': dailyReminder,
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? email,
    String? avatarUrl,
    String? username,
    int? level,
    int? xp,
    int? coinsBalance,
    int? currentStreak,
    int? bestStreak,
    int? quizzesPlayed,
    int? correctAnswers,
    int? totalAnswers,
    int? stateRank,
    bool? dailyReminder,
  }) {
    return ProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      username: username ?? this.username,
      userCode: userCode,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coinsBalance: coinsBalance ?? this.coinsBalance,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      quizzesPlayed: quizzesPlayed ?? this.quizzesPlayed,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalAnswers: totalAnswers ?? this.totalAnswers,
      referralCode: referralCode,
      referredBy: referredBy,
      stateRank: stateRank ?? this.stateRank,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      createdAt: createdAt,
    );
  }
}
