import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/app_settings_provider.dart';
import 'screens/website/website_screen.dart';
import 'core/utils/url_strategy_helper.dart';

void main() async {
  // Configure Web browser URL to keep showing domain only without sub-pages (must run before binding initialization)
  configureDomainOnlyUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  // Set system navigation bar & status bar colors for dark navy theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surfaceContainerLowest,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Pre-load web login cache before any route or widget builds for zero-delay dashboard resolution
  await WebsiteScreen.initPersistence();

  // Initialize Supabase Client
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
    debug: false,
  );

  runApp(
    const ProviderScope(
      child: QuizRupiApp(),
    ),
  );
}

class QuizRupiApp extends ConsumerWidget {
  const QuizRupiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Global Realtime Remote Control Listener (reacts to live toggles by Admin)
    ref.listen<AppSettingsState>(appSettingsProvider, (previous, next) {
      if (previous == null) return;
      if (previous.settings.showWebsite == next.settings.showWebsite &&
          previous.settings.websiteUrl == next.settings.websiteUrl) {
        return;
      }

      final settings = next.settings;
      try {
        final currentPath = router.routeInformationProvider.value.uri.path;

        // Do not interrupt initial splash loading
        if (currentPath == '/splash') return;

        if (settings.isWebsiteModeValid && currentPath != '/website') {
          final targetUrl = WebsiteScreen.resolveTargetWebUrl(settings.websiteUrl ?? '');
          router.go('/website', extra: {
            'url': targetUrl,
            'title': settings.websiteTitle,
          });
        } else if (!settings.isWebsiteModeValid && currentPath == '/website') {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            router.go('/');
          } else {
            router.go('/login');
          }
        }
      } catch (e) {
        debugPrint('Remote control listener notice: $e');
      }
    });

    return MaterialApp.router(
      title: 'QuizRupi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
