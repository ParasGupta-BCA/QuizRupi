class SupabaseConstants {
  static const String supabaseUrl = 'https://colxieispudhsaisydqr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvbHhpZWlzcHVkaHNhaXN5ZHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA1MTIyNDEsImV4cCI6MjEwNjA4ODI0MX0.aGTjDiWhxW4Gu6KcYLLkdweOtg-RLVApvJhCBRJLgfI';

  // Tables
  static const String tableAdminUsers = 'admin_users';
  static const String tableAppSettings = 'app_settings';
  static const String tableAppSettingsHistory = 'app_settings_history';
  static const String tableProfiles = 'profiles';
  static const String tableQuizCategories = 'quiz_categories';
  static const String tableQuestions = 'questions';
  static const String tableQuizAttempts = 'quiz_attempts';
  static const String tableDailyChallenges = 'daily_challenges';
  static const String tableBooks = 'books';
  static const String tableBookHighlights = 'book_highlights';
  static const String tableOrders = 'orders';
  static const String tableOrderItems = 'order_items';
  static const String tableCoinTransactions = 'coin_transactions';
  static const String tableVouchers = 'vouchers';
  static const String tableBanners = 'banners';
  static const String tableAnnouncements = 'announcements';
  static const String tablePromotions = 'promotions';
  static const String tableBadges = 'badges';

  // Buckets
  static const String bucketBookCovers = 'book-covers';
  static const String bucketQuestionImages = 'question-images';
  static const String bucketBanners = 'banners';
}
