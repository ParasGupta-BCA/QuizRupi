import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/stat_card.dart';
import '../../providers/app_control_provider.dart';
import '../../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final appControlState = ref.watch(appControlProvider);
    final isWebsiteMode = appControlState.settings.showWebsite;
    final websiteUrl = appControlState.settings.websiteUrl;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== APP MODE HERO BANNER ====================
              _buildAppModeHeroCard(context, ref, isDark, isWebsiteMode, websiteUrl),
              const SizedBox(height: 24),

              // Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Real-Time Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh stats',
                    onPressed: () => ref.invalidate(dashboardStatsProvider),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ==================== STATS GRID ====================
              statsAsync.when(
                loading: () => const SkeletonListLoader(count: 3),
                error: (err, _) => Card(
                  color: AppColors.errorLight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Error loading stats: $err')),
                        TextButton(
                          onPressed: () => ref.invalidate(dashboardStatsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (stats) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width > 1100
                          ? 4
                          : (width > 700 ? 3 : 2);

                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: width > 900 ? 1.6 : (width > 600 ? 1.35 : 1.15),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          StatCard(
                            title: 'Total Users',
                            value: NumberFormat('#,###').format(stats.totalUsers),
                            subtitle: '${stats.activeToday} estimated active',
                            icon: Icons.people_alt_rounded,
                            iconColor: AppColors.primary,
                            onTap: () => context.go('/users'),
                          ),
                          StatCard(
                            title: 'Quizzes Played',
                            value: NumberFormat('#,###').format(stats.quizzesPlayedToday),
                            subtitle: 'Today across all categories',
                            icon: Icons.quiz_rounded,
                            iconColor: Colors.deepPurple,
                            onTap: () => context.go('/quiz'),
                          ),
                          StatCard(
                            title: 'Total Orders',
                            value: '${stats.totalOrders}',
                            subtitle: '${stats.ordersPending} pending fulfillment',
                            icon: Icons.local_shipping_rounded,
                            iconColor: Colors.orange,
                            onTap: () => context.go('/orders'),
                          ),
                          StatCard(
                            title: 'Revenue Today',
                            value: currencyFormat.format(stats.revenueToday),
                            subtitle: 'This Month: ${currencyFormat.format(stats.revenueThisMonth)}',
                            icon: Icons.currency_rupee_rounded,
                            iconColor: AppColors.success,
                            onTap: () => context.go('/orders'),
                          ),
                          StatCard(
                            title: 'Coins Distributed',
                            value: NumberFormat('#,###').format(stats.coinsGivenToday),
                            subtitle: 'From quizzes & bonus awards',
                            icon: Icons.monetization_on_rounded,
                            iconColor: AppColors.secondary,
                            onTap: () => context.go('/users'),
                          ),
                          StatCard(
                            title: 'Active Books',
                            value: '7 Products',
                            subtitle: 'All in UPSC/SSC prep',
                            icon: Icons.menu_book_rounded,
                            iconColor: Colors.indigo,
                            onTap: () => context.go('/books'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),

              // ==================== CHARTS SECTION ====================
              const Text(
                'Performance Trends',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 850;
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildRevenueChart(isDark)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildQuizActivityChart(isDark)),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildRevenueChart(isDark),
                        const SizedBox(height: 16),
                        _buildQuizActivityChart(isDark),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppModeHeroCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isWebsiteMode,
    String? websiteUrl,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isWebsiteMode
              ? Colors.purple.withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isWebsiteMode
                ? [
                    Colors.purple.shade900.withValues(alpha: isDark ? 0.35 : 0.08),
                    Colors.indigo.shade900.withValues(alpha: isDark ? 0.25 : 0.04),
                  ]
                : [
                    AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.08),
                    AppColors.primaryDark.withValues(alpha: isDark ? 0.15 : 0.02),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isWebsiteMode ? Colors.purple : AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.radio_button_checked, color: Colors.white, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        isWebsiteMode ? 'LIVE: WEBSITE MODE' : 'LIVE: STORE MODE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/app-control'),
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Remote Settings'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: isWebsiteMode ? Colors.purple : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: (isWebsiteMode ? Colors.purple : AppColors.primary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isWebsiteMode ? Icons.language_rounded : Icons.storefront_rounded,
                    color: isWebsiteMode ? Colors.purple : AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isWebsiteMode
                            ? 'Website Mode Active'
                            : 'Store & Quiz Mode Active',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isWebsiteMode
                            ? 'Users see in-app website: ${websiteUrl ?? "No URL configured"}. Store & quizzes hidden.'
                            : 'Users have full access to Quizzes, UPSC/SSC Books Store, Battles, and Profile.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: isWebsiteMode,
                  // ignore: deprecated_member_use
                  activeColor: Colors.purple,
                  onChanged: (val) {
                    ref.read(appControlProvider.notifier).quickToggleMode(val);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Revenue Trend (Last 7 Days)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.trending_up, color: AppColors.success, size: 20),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          final idx = val.toInt();
                          if (idx >= 0 && idx < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(days[idx], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 799),
                        FlSpot(1, 1499),
                        FlSpot(2, 999),
                        FlSpot(3, 2199),
                        FlSpot(4, 1850),
                        FlSpot(5, 3499),
                        FlSpot(6, 2899),
                      ],
                      isCurved: true,
                      color: AppColors.success,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.success.withValues(alpha: 0.15),
                      ),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizActivityChart(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Quiz Plays',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          final idx = val.toInt();
                          if (idx >= 0 && idx < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(days[idx], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 42, color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 65, color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 58, color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 90, color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 82, color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 120, color: AppColors.secondary, width: 14, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 105, color: AppColors.secondary, width: 14, borderRadius: BorderRadius.circular(4))]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
