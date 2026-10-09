import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import 'app_logo.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/app_control_provider.dart';
import '../../providers/theme_provider.dart';

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
}

const List<NavigationItem> navItems = [
  NavigationItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    route: '/dashboard',
  ),
  NavigationItem(
    label: 'App Control',
    icon: Icons.settings_remote_outlined,
    selectedIcon: Icons.settings_remote_rounded,
    route: '/app-control',
  ),
  NavigationItem(
    label: 'Books Store',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book_rounded,
    route: '/books',
  ),
  NavigationItem(
    label: 'Orders',
    icon: Icons.shopping_bag_outlined,
    selectedIcon: Icons.shopping_bag_rounded,
    route: '/orders',
  ),
  NavigationItem(
    label: 'Users',
    icon: Icons.people_outline,
    selectedIcon: Icons.people_rounded,
    route: '/users',
  ),
  NavigationItem(
    label: 'Quiz Content',
    icon: Icons.quiz_outlined,
    selectedIcon: Icons.quiz_rounded,
    route: '/quiz',
  ),
  NavigationItem(
    label: 'Promotions',
    icon: Icons.campaign_outlined,
    selectedIcon: Icons.campaign_rounded,
    route: '/promotions',
  ),
  NavigationItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    route: '/settings',
  ),
];

class ResponsiveScaffold extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const ResponsiveScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  int _calculateSelectedIndex() {
    for (int i = 0; i < navItems.length; i++) {
      if (currentRoute.startsWith(navItems[i].route)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;
    final selectedIndex = _calculateSelectedIndex();
    final appControlState = ref.watch(appControlProvider);
    final isWebsiteMode = appControlState.settings.showWebsite;
    final user = ref.watch(adminAuthProvider).user;

    return Scaffold(
      appBar: isWide
          ? null
          : AppBar(
              titleSpacing: 0,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(
                    size: 28,
                    borderRadius: 7,
                    showShadow: false,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      navItems[selectedIndex].label,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: [
                _buildModePill(context, ref, isWebsiteMode),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  tooltip: 'Toggle Theme',
                  icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20),
                  onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  onPressed: () => _confirmLogout(context, ref),
                ),
                const SizedBox(width: 4),
              ],
            ),
      drawer: isWide ? null : _buildMobileDrawer(context, ref, selectedIndex, isDark, user?.email),
      body: Row(
        children: [
          if (isWide) _buildDesktopSidebar(context, ref, selectedIndex, isDark, user?.email, isWebsiteMode),
          Expanded(
            child: Column(
              children: [
                if (isWide) _buildDesktopTopBar(context, ref, selectedIndex, isDark, isWebsiteMode, user?.email),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex.clamp(0, 3),
              onDestinationSelected: (idx) {
                context.go(navItems[idx].route);
              },
              destinations: [
                NavigationDestination(
                  icon: Icon(navItems[0].icon),
                  selectedIcon: Icon(navItems[0].selectedIcon),
                  label: navItems[0].label,
                ),
                NavigationDestination(
                  icon: Icon(navItems[1].icon),
                  selectedIcon: Icon(navItems[1].selectedIcon),
                  label: 'App Control',
                ),
                NavigationDestination(
                  icon: Icon(navItems[2].icon),
                  selectedIcon: Icon(navItems[2].selectedIcon),
                  label: 'Books',
                ),
                NavigationDestination(
                  icon: Icon(navItems[3].icon),
                  selectedIcon: Icon(navItems[3].selectedIcon),
                  label: 'Orders',
                ),
              ],
            ),
    );
  }

  Widget _buildModePill(BuildContext context, WidgetRef ref, bool isWebsiteMode) {
    return GestureDetector(
      onTap: () => context.go('/app-control'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isWebsiteMode
              ? Colors.purple.withValues(alpha: 0.15)
              : AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isWebsiteMode ? Colors.purple : AppColors.success,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isWebsiteMode ? Colors.purple : AppColors.success,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isWebsiteMode ? 'WEBSITE MODE' : 'STORE MODE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isWebsiteMode ? Colors.purple : AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTopBar(
    BuildContext context,
    WidgetRef ref,
    int selectedIndex,
    bool isDark,
    bool isWebsiteMode,
    String? userEmail,
  ) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            navItems[selectedIndex].label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              _buildModePill(context, ref, isWebsiteMode),
              const SizedBox(width: 16),
              IconButton(
                tooltip: 'Toggle Theme',
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                offset: const Offset(0, 48),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          (userEmail?.isNotEmpty == true ? userEmail![0].toUpperCase() : 'A'),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        userEmail ?? 'Admin',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'settings',
                    child: const Row(
                      children: [
                        Icon(Icons.settings, size: 18),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: const Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (val) {
                  if (val == 'settings') {
                    context.go('/settings');
                  } else if (val == 'logout') {
                    _confirmLogout(context, ref);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    WidgetRef ref,
    int selectedIndex,
    bool isDark,
    String? userEmail,
    bool isWebsiteMode,
  ) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Brand Logo
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const AppLogo(
                  size: 38,
                  borderRadius: 10,
                  showShadow: true,
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Super',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          ' Quiz',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Admin Control Center',
                      style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Nav list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = index == selectedIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: InkWell(
                    onTap: () => context.go(item.route),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: isSelected ? AppColors.primary : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                          ),
                          if (item.route == '/app-control')
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isWebsiteMode ? Colors.purple : AppColors.success,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Bottom user block
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (userEmail?.isNotEmpty == true ? userEmail![0].toUpperCase() : 'A'),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userEmail ?? 'Super Admin',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Administrator',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.grey),
                  onPressed: () => _confirmLogout(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(
    BuildContext context,
    WidgetRef ref,
    int selectedIndex,
    bool isDark,
    String? userEmail,
  ) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const AppLogo(
                    size: 40,
                    borderRadius: 10,
                    showShadow: false,
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Super Quiz Admin',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Management Console',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                itemCount: navItems.length,
                itemBuilder: (context, idx) {
                  final item = navItems[idx];
                  final isSelected = idx == selectedIndex;
                  return ListTile(
                    leading: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      color: isSelected ? AppColors.primary : Colors.grey,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                    selected: isSelected,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      Navigator.pop(context); // close drawer
                      context.go(item.route);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmLogout(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of the Admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(adminAuthProvider.notifier).signOut();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
