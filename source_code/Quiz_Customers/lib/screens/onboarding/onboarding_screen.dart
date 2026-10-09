import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Utility Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryContainer.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Step ${_currentIndex + 1} of 3',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      backgroundColor: AppColors.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: AppColors.outlineVariant.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Skip',
                          style: AppTextStyles.labelMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                children: [
                  _buildSlide1(),
                  _buildSlide2(),
                  _buildSlide3(),
                ],
              ),
            ),

            // Bottom Navigation & Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryContainer
                              : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryContainer.withOpacity(0.5),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentIndex < 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finishOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentIndex == 2 ? 'Get Started Now' : 'Continue',
                            style: AppTextStyles.labelLg.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentIndex == 2 ? '🚀' : '→',
                            style: const TextStyle(fontSize: 18),
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
      ),
    );
  }

  // Slide 1: Learn Smarter with Fun Daily Quizzes
  Widget _buildSlide1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Showcase Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.outlineVariant.withOpacity(0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top floating badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPillChip(Icons.local_fire_department, '7 Day Streak', AppColors.secondary),
                    _buildPillChip(Icons.monetization_on, '+250 Rupi', AppColors.secondary),
                  ],
                ),
                const SizedBox(height: 14),
                // Book Showcase Image
                SizedBox(
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuDe9NSqRvnIyQADrWRrhQsxi5WW0Q66Fya9HEMMDKfdp1B8AaoYADVm144kRqjOBDkV1dcvRObeZugY7UYIyc8qCSCe9w0ubED9rJJsW7hc9bEcfc7YtYC83FVtWZlNibK9ywfytpDfJNQGjqdSXyhl26624mSmVlqsBNaw7Fn1gUUb-siWqcLPnNHZFXNtW9rqU7n1QbBQLcDyoR914h677bDv55ULamc5R2a29Hnv3V4-3NBxHWR1WKRkRUBMZKo-1xM',
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 10,
                        child: _buildFloatingBadge('Level 01', 'Top 5%', Icons.emoji_events),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.outlineVariant.withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: AppColors.tertiary, size: 16),
                              SizedBox(width: 4),
                              Text('New Delhi +10pt', style: TextStyle(color: AppColors.tertiary, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Category Pills
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildCategoryTag('History', Icons.history_edu),
                    _buildCategoryTag('World GK', Icons.public),
                    _buildCategoryTag('Science', Icons.science),
                    _buildCategoryTag('Sports', Icons.sports_soccer),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Learn Smarter with\nFun Daily Quizzes',
            style: AppTextStyles.headlineXlMobile.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Explore thousands of curated questions across Indian History, Current Affairs, Science, and Aptitude tailored for competitive exams.',
            style: AppTextStyles.bodyMd.copyWith(
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Slide 2: Challenge Friends & Climb the Ranks
  Widget _buildSlide2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPillChip(Icons.military_tech, 'State Rank #42', AppColors.primary),
                    _buildPillChip(Icons.bolt, '1v1 Live Duels', AppColors.secondary),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCmBJuLJio1BBp2_steJkbTMlj1A8K0gy4A1Cw3a3tieJHcerbGC40Zh6ppElKKe4Tg8hFhfzjSQNRp12KEPb_kgtUBXmMq-QepRuxtWwBqkVjcAw5UOx6KNKpJjFpQHOfdGi5piunnk5MBDUH4f-MyQs7unMuRA3S5KLvDZChbp9JF_HNZrs0OwB5HwZ4R8n5Eb2yX7n04j44wKdJYg7ycUgr3YEFGP841agiXGRSSgfxUZdCXLX-3OQ',
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniFeature(Icons.sports_kabaddi, 'Live 1v1', AppColors.primary),
                    _buildMiniFeature(Icons.emoji_events, 'Tournaments', AppColors.secondary),
                    _buildMiniFeature(Icons.workspace_premium, 'Earn Points', AppColors.tertiary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Challenge Friends &\nClimb the Ranks',
            style: AppTextStyles.headlineXlMobile.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Play real-time 1v1 quiz battles, take on weekly Mega Contests, and earn Quiz Points for each right answer.',
            style: AppTextStyles.bodyMd.copyWith(
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Slide 3: Turn Virtual Coins Into Real Printed Books
  Widget _buildSlide3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuANETEWGSy4lH7GeJcR30exDqBrhWP5ZSsRIwr0F56r1sSxHeBgsjHBrATCDXIs89UQSOgOt2YkieQRfT4jBaAOCB_RPmEU0ilaWOn7urDDM6-ZCHnryuY6VA-xy5L6QeqYUCKoTMytd-DtkUzqBWpK5CPQAe-E9p8NCgjKo4GW8pGlvE1z4zcMQQPYaTSM70MgtuqP1On89JjGQQAWuEaLvK2f0irX4C3mUFXgbL40zgEpqSZrfYmtwXeJcrJiANyckC0',
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildBentoReward(
                        Icons.local_shipping,
                        'Free Shipping',
                        'To your door',
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBentoReward(
                        Icons.currency_rupee,
                        'UPI / COD',
                        'Safe payment',
                        AppColors.tertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBentoReward(
                        Icons.menu_book,
                        'Exam Guides',
                        '1000+ MCQs',
                        AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Discover Quality\nReal Printed Books',
            style: AppTextStyles.headlineXlMobile.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Boost your preparation! Explore bestselling printed MCQs, flashcards, and exam preparation study guides delivered to your doorstep.',
            style: AppTextStyles.bodyMd.copyWith(
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPillChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBadge(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.secondary, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: AppColors.primary, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppColors.onSurface, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildMiniFeature(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.onSurface, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildBentoReward(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 8),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
