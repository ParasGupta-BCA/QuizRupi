import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/coin_badge.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/quiz_provider.dart';

class ProfileOrdersScreen extends ConsumerStatefulWidget {
  const ProfileOrdersScreen({super.key});

  @override
  ConsumerState<ProfileOrdersScreen> createState() => _ProfileOrdersScreenState();
}

class _ProfileOrdersScreenState extends ConsumerState<ProfileOrdersScreen> {
  bool _dailyReminder = true;

  static const String _termsUrl =
      'https://quizrupi.blogspot.com/2026/09/terms-and-conditions-for-quizrupi.html';
  static const String _privacyUrl =
      'https://quizrupi.blogspot.com/2026/09/privacy-policy-for-quizrupi.html';

  Future<void> _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Could not launch $urlString: $e');
    }
  }

  void _showEditProfileDialog(String currentName) {
    final nameCtrl = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Profile', style: AppTextStyles.headlineSm),
        content: TextField(
          controller: nameCtrl,
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: AppTextStyles.bodySm.copyWith(color: AppColors.outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                final userId = ref.read(currentUserIdProvider);
                if (userId != null) {
                  final service = ref.read(supabaseServiceProvider);
                  await service.updateProfileData(userId, {'full_name': nameCtrl.text.trim()});
                  ref.read(profileRefreshTriggerProvider.notifier).state++;
                }
              }
              if (mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.support_agent, color: AppColors.primaryContainer),
            const SizedBox(width: 8),
            Text('QuizRupi Support', style: AppTextStyles.headlineSm.copyWith(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need help with an order or quiz reward?',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('• Email: support@quizrupi.app', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('• WhatsApp: +91 98765 43210', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('• Delivery Hours: Mon-Sat, 9AM-8PM', style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 12),
            Divider(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _launchURL(_termsUrl),
                  child: Text(
                    'Terms of Service',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _launchURL(_privacyUrl),
                  child: Text(
                    'Privacy Policy',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out?', style: AppTextStyles.headlineSm),
        content: const Text('Are you sure you want to log out of QuizRupi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimsonRed),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final ordersAsync = ref.watch(userOrdersProvider);
    final badgesAsync = ref.watch(userBadgesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryContainer,
          backgroundColor: AppColors.surfaceContainer,
          onRefresh: () async {
            ref.read(profileRefreshTriggerProvider.notifier).state++;
            ref.read(ordersRefreshTriggerProvider.notifier).state++;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            child: profileAsync.when(
              data: (profile) {
                final fullName = profile?.fullName ?? 'Quiz Champ';
                final username = profile?.username ?? 'quizzer';
                final userCode = profile?.userCode ?? 'QZ-88219';
                final coins = profile?.coinsBalance ?? 0;
                final level = profile?.level ?? 1;
                final xp = profile?.xp ?? 0;
                final quizzesPlayed = profile?.quizzesPlayed ?? 0;
                final winAccuracy = profile?.winAccuracy ?? 0.0;
                final streak = profile?.currentStreak ?? 0;

                final currentLevelXp = xp % 250;
                final progressFraction = (currentLevelXp / 250.0).clamp(0.0, 1.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryContainer.withOpacity(0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.lightbulb, color: AppColors.secondary, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'QuizRupi',
                              style: AppTextStyles.headlineSm.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            CoinBadge(
                              coins: coins,
                              onTap: () => context.push('/wallet'),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.notifications_none, color: AppColors.onSurfaceVariant),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No new notifications')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Avatar with border
                              Stack(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [AppColors.secondary, AppColors.primaryContainer],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.secondary.withOpacity(0.3),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: ClipOval(
                                      child: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                                          ? Image.network(
                                              profile.avatarUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                            )
                                          : const Icon(Icons.person, color: Colors.white, size: 32),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: AppColors.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.verified,
                                        color: AppColors.onSecondaryFixed,
                                        size: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),

                              // Name & Handle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName,
                                      style: AppTextStyles.headlineSm.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '@$username • ID: $userCode',
                                      style: AppTextStyles.bodySm.copyWith(
                                        color: AppColors.outline,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.military_tech, size: 14, color: AppColors.secondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Pro Quizzer Lvl 0$level',
                                            style: AppTextStyles.labelSm.copyWith(
                                              color: AppColors.secondary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Edit Button
                              OutlinedButton.icon(
                                onPressed: () => _showEditProfileDialog(fullName),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.3)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.edit, size: 14, color: AppColors.onSurface),
                                label: Text(
                                  'Edit',
                                  style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurface),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Quick Wallet Strip
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: AppColors.secondaryContainer.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.stars_rounded, color: AppColors.secondary, size: 20),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'QUIZ POINTS',
                                              style: AppTextStyles.labelSm.copyWith(
                                                color: AppColors.outline,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              '$coins PTS',
                                              style: AppTextStyles.priceDisplay.copyWith(
                                                color: AppColors.secondary,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => context.push('/wallet'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryContainer,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.history, size: 14),
                                      label: Text(
                                        'View Points',
                                        style: AppTextStyles.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.confirmation_number, color: AppColors.emeraldGreen, size: 16),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Active Voucher', style: AppTextStyles.labelSm.copyWith(fontSize: 9, color: AppColors.outline)),
                                                  Text('₹150 Discount', style: AppTextStyles.labelSm.copyWith(color: AppColors.emeraldGreen, fontWeight: FontWeight.w700)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.leaderboard, color: AppColors.primaryContainer, size: 16),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('State Rank', style: AppTextStyles.labelSm.copyWith(fontSize: 9, color: AppColors.outline)),
                                                  Text('#${profile?.stateRank ?? 42} (Top 5%)', style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryContainer, fontWeight: FontWeight.w700)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Performance Overview 4-Card Bento Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Performance Overview',
                          style: AppTextStyles.headlineSm.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'All Time',
                          style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatTile(
                          'Quizzes Played',
                          '$quizzesPlayed',
                          '+14 this week',
                          Icons.quiz,
                          AppColors.primaryContainer,
                          AppColors.emeraldGreen,
                        ),
                        _buildStatTile(
                          'Win Accuracy',
                          '${winAccuracy.toStringAsFixed(1)}%',
                          'High Accuracy tier',
                          Icons.radar,
                          AppColors.emeraldGreen,
                          AppColors.outline,
                        ),
                        _buildStatTile(
                          'Current Streak',
                          '$streak Days 🔥',
                          'Personal best: 14d',
                          Icons.local_fire_department,
                          AppColors.secondary,
                          AppColors.outline,
                        ),
                        _buildStatTile(
                          'Book Orders',
                          '3 Books 📚',
                          'Delivered to home',
                          Icons.auto_stories,
                          AppColors.primaryContainer,
                          AppColors.outline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Level Progress & XP Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.workspace_premium, color: AppColors.secondary, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Level $level • GK Master',
                                    style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              Text(
                                '$currentLevelXp / 250 XP',
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progressFraction,
                              minHeight: 8,
                              backgroundColor: AppColors.surfaceContainerHigh,
                              valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Only ${250 - currentLevelXp} XP needed to unlock Level ${level + 1} & ₹50 Book Voucher!',
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.outline, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Badges & Trophies Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Badges & Trophies',
                          style: AppTextStyles.headlineSm.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        badgesAsync.maybeWhen(
                          data: (bList) => Text(
                            '${bList.where((b) => b.isUnlocked).length} Unlocked',
                            style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryContainer),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    badgesAsync.when(
                      data: (badges) {
                        return Row(
                          children: badges.map((badge) {
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: badge.isUnlocked
                                        ? AppColors.secondary.withOpacity(0.3)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: badge.isUnlocked
                                            ? AppColors.secondary.withOpacity(0.18)
                                            : AppColors.surfaceContainerHighest,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        badge.isUnlocked ? Icons.military_tech : Icons.lock_outline,
                                        color: badge.isUnlocked ? AppColors.secondary : AppColors.outline,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      badge.title,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.labelSm.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: badge.isUnlocked ? AppColors.onSurface : AppColors.outline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      badge.isUnlocked ? 'Unlocked' : 'Locked',
                                      style: AppTextStyles.bodySm.copyWith(
                                        fontSize: 9,
                                        color: badge.isUnlocked ? AppColors.secondary : AppColors.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),

                    // Recent Book Orders Quick Preview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping, color: AppColors.secondary, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'Recent Book Orders',
                              style: AppTextStyles.headlineSm.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        ordersAsync.maybeWhen(
                          data: (orders) => Text(
                            '(${orders.length} orders)',
                            style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryContainer),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    ordersAsync.when(
                      data: (orders) {
                        if (orders.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.outline),
                                  const SizedBox(height: 8),
                                  Text('No book orders yet', style: AppTextStyles.labelMd),
                                  const SizedBox(height: 6),
                                  ElevatedButton(
                                    onPressed: () => context.go('/shop'),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
                                    child: const Text('Order Quiz Book', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final latestOrder = orders.first;
                        final firstItem = latestOrder.items.isNotEmpty
                            ? latestOrder.items.first
                            : null;
                        final bookTitle = firstItem?.book?.title ?? 'GK Master Quiz Book (1000+ MCQs)';
                        final coverUrl = firstItem?.book?.coverImageUrl;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Cover
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 52,
                                      height: 74,
                                      color: AppColors.surfaceContainerHigh,
                                      child: coverUrl != null
                                          ? Image.network(coverUrl, fit: BoxFit.cover)
                                          : const Icon(Icons.menu_book, color: AppColors.outline),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bookTitle,
                                          style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${latestOrder.totalAmount.toInt()} • Hardcopy Print',
                                          style: AppTextStyles.bodySm.copyWith(color: AppColors.outline),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.local_shipping, size: 14, color: AppColors.emeraldGreen),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Status: ${latestOrder.status}',
                                              style: AppTextStyles.labelSm.copyWith(
                                                color: AppColors.emeraldGreen,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Tracking: ${latestOrder.trackingId}',
                                      style: AppTextStyles.bodySm.copyWith(fontSize: 11, color: AppColors.outline),
                                    ),
                                    GestureDetector(
                                      onTap: () => context.push('/order-tracking/${latestOrder.id}'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.route, size: 14, color: AppColors.primaryContainer),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Track Order',
                                              style: AppTextStyles.labelSm.copyWith(
                                                color: AppColors.primaryContainer,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),

                    // Account & Preferences Menu Section
                    Text(
                      'Account & Preferences',
                      style: AppTextStyles.headlineSm.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          // Refer Friends & Earn
                          _buildMenuItem(
                            icon: Icons.card_giftcard,
                            iconColor: AppColors.secondary,
                            title: 'Refer Friends & Earn',
                            subtitle: 'Invite study buddies, earn +250 points each',
                            tag: '+250 PTS',
                            tagColor: AppColors.secondary,
                            onTap: () => context.push('/refer-earn'),
                          ),
                          _buildDivider(),

                          // Saved Addresses
                          _buildMenuItem(
                            icon: Icons.location_on,
                            iconColor: AppColors.primaryContainer,
                            title: 'Saved Delivery Addresses',
                            subtitle: 'Manage shipping locations for book orders',
                            onTap: () => context.push('/addresses'),
                          ),
                          _buildDivider(),

                          // Quiz History
                          _buildMenuItem(
                            icon: Icons.history_edu,
                            iconColor: AppColors.emeraldGreen,
                            title: 'Quiz History & Scorecard',
                            subtitle: 'Review wrong answers & solutions',
                            onTap: () => context.push('/quiz-history'),
                          ),
                          _buildDivider(),

                          // Daily Quiz Reminder Toggle
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.notifications_active, color: AppColors.secondary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Daily Quiz Reminder (9:00 PM)',
                                        style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        'Maintain your daily study streak',
                                        style: AppTextStyles.bodySm.copyWith(color: AppColors.outline, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _dailyReminder,
                                  activeColor: AppColors.primaryContainer,
                                  onChanged: (val) {
                                    setState(() => _dailyReminder = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          _buildDivider(),

                          // App Theme
                          _buildMenuItem(
                            icon: Icons.dark_mode,
                            iconColor: AppColors.primaryContainer,
                            title: 'App Theme',
                            subtitle: 'Dark Mode (Optimized for study)',
                            tag: 'ACTIVE',
                            tagColor: AppColors.primaryContainer,
                            onTap: null,
                          ),
                          _buildDivider(),

                          // Help Desk & Support
                          _buildMenuItem(
                            icon: Icons.support_agent,
                            iconColor: AppColors.onSurfaceVariant,
                            title: 'Help Desk & Order Support',
                            subtitle: 'FAQs, book delivery issues & refunds',
                            onTap: _showSupportDialog,
                          ),
                          _buildDivider(),

                          // Terms of Service
                          _buildMenuItem(
                            icon: Icons.description_outlined,
                            iconColor: AppColors.primary,
                            title: 'Terms of Service',
                            subtitle: 'Terms and conditions for using QuizRupi',
                            onTap: () => _launchURL(_termsUrl),
                          ),
                          _buildDivider(),

                          // Privacy Policy
                          _buildMenuItem(
                            icon: Icons.privacy_tip_outlined,
                            iconColor: AppColors.primary,
                            title: 'Privacy Policy',
                            subtitle: 'How QuizRupi protects and uses your data',
                            onTap: () => _launchURL(_privacyUrl),
                          ),
                          _buildDivider(),

                          // Log Out
                          _buildMenuItem(
                            icon: Icons.logout,
                            iconColor: AppColors.crimsonRed,
                            title: 'Log Out',
                            subtitle: 'Safely disconnect from device',
                            isDestructive: true,
                            onTap: _handleLogout,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(50),
                  child: CircularProgressIndicator(color: AppColors.primaryContainer),
                ),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color subColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.labelSm.copyWith(color: AppColors.outline)),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          Text(
            value,
            style: AppTextStyles.headlineSm.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            subtitle,
            style: AppTextStyles.bodySm.copyWith(color: subColor, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? tag,
    Color? tagColor,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.crimsonRed.withOpacity(0.15)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.labelMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDestructive ? AppColors.crimsonRed : AppColors.onSurface,
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: (tagColor ?? AppColors.primaryContainer).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: AppTextStyles.labelSm.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: tagColor ?? AppColors.primaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.outline, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, size: 18, color: AppColors.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.outlineVariant.withOpacity(0.2),
      indent: 62,
    );
  }
}
