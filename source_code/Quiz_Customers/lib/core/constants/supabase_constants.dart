class SupabaseConstants {
  static const String supabaseUrl = 'https://colxieispudhsaisydqr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvbHhpZWlzcHVkaHNhaXN5ZHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA1MTIyNDEsImV4cCI6MjEwNjA4ODI0MX0.aGTjDiWhxW4Gu6KcYLLkdweOtg-RLVApvJhCBRJLgfI';

  // Table Names
  static const String tableProfiles = 'profiles';
  static const String tableQuizCategories = 'quiz_categories';
  static const String tableQuestions = 'questions';
  static const String tableQuizAttempts = 'quiz_attempts';
  static const String tableQuizAttemptAnswers = 'quiz_attempt_answers';
  static const String tableDailyChallenges = 'daily_challenges';
  static const String tableDailyChallengeProgress = 'daily_challenge_progress';
  static const String tableLiveBattles = 'live_battles';
  static const String tableLeaderboardDaily = 'leaderboard_daily';
  static const String tableBadges = 'badges';
  static const String tableUserBadges = 'user_badges';
  static const String tableBooks = 'books';
  static const String tableBookHighlights = 'book_highlights';
  static const String tableAddresses = 'addresses';
  static const String tableCartItems = 'cart_items';
  static const String tableOrders = 'orders';
  static const String tableOrderItems = 'order_items';
  static const String tableCoinTransactions = 'coin_transactions';
  static const String tableVouchers = 'vouchers';
  static const String tableAppSettings = 'app_settings';
  static const String tableAppSettingsHistory = 'app_settings_history';
  static const String tableBanners = 'banners';
  static const String tableAnnouncements = 'announcements';
  static const String tablePromotions = 'promotions';

  // Storage Buckets
  static const String bucketBookCovers = 'book-covers';
}
