import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../data/models/app_settings_model.dart';

class AppSettingsState {
  final AppSettingsModel settings;
  final bool isLoading;
  final bool isOffline;
  final Object? error;

  const AppSettingsState({
    this.settings = const AppSettingsModel(),
    this.isLoading = false,
    this.isOffline = false,
    this.error,
  });

  AppSettingsState copyWith({
    AppSettingsModel? settings,
    bool? isLoading,
    bool? isOffline,
    Object? error,
  }) {
    return AppSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isOffline: isOffline ?? this.isOffline,
      error: error,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettingsState> {
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;

  static const _keyShowWebsite = 'app_settings_show_website';
  static const _keyWebsiteUrl = 'app_settings_website_url';
  static const _keyWebsiteTitle = 'app_settings_website_title';
  static const _keyUpiId = 'app_settings_upi_id';
  static const _keyPayeeName = 'app_settings_payee_name';
  static const _keyIsUpiEnabled = 'app_settings_is_upi_enabled';
  static const _keyUpdatedAt = 'app_settings_updated_at';

  @override
  AppSettingsState build() {
    ref.onDispose(() {
      _realtimeSubscription?.cancel();
    });
    Future.microtask(() => loadInitialSettings());
    return const AppSettingsState(isLoading: true);
  }

  /// Fetches settings at startup with 1.5-second timeout and offline cache fallback
  Future<AppSettingsModel> loadInitialSettings() async {
    AppSettingsModel cachedSettings = const AppSettingsModel();

    // 1. Read cached settings from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_keyShowWebsite)) {
        cachedSettings = AppSettingsModel(
          id: 1,
          showWebsite: prefs.getBool(_keyShowWebsite) ?? false,
          websiteUrl: prefs.getString(_keyWebsiteUrl),
          websiteTitle: prefs.getString(_keyWebsiteTitle),
          upiId: prefs.getString(_keyUpiId) ?? 'quizrupi@upi',
          payeeName: prefs.getString(_keyPayeeName) ?? 'QuizRupi Store',
          isUpiEnabled: prefs.getBool(_keyIsUpiEnabled) ?? true,
          updatedAt: prefs.getString(_keyUpdatedAt) != null
              ? DateTime.tryParse(prefs.getString(_keyUpdatedAt)!)
              : null,
        );
      }
    } catch (e) {
      debugPrint('Error reading cached app_settings: $e');
    }

    // 2. Fetch fresh settings from Supabase with 1.5-second timeout
    AppSettingsModel freshSettings = cachedSettings;
    bool isOffline = false;

    try {
      final response = await Supabase.instance.client
          .from(SupabaseConstants.tableAppSettings)
          .select()
          .eq('id', 1)
          .maybeSingle()
          .timeout(const Duration(milliseconds: 1500));

      if (response != null) {
        freshSettings = AppSettingsModel.fromJson(response);
        await _saveToCache(freshSettings);
      }
    } catch (e) {
      debugPrint('Supabase app_settings fetch failed or timed out: $e. Using cache.');
      isOffline = true;
    }

    state = state.copyWith(
      settings: freshSettings,
      isLoading: false,
      isOffline: isOffline,
    );

    // 3. Connect real-time subscription
    try {
      _startRealtimeSubscription();
    } catch (e) {
      debugPrint('Error starting realtime app_settings: $e');
    }

    return freshSettings;
  }

  void _startRealtimeSubscription() {
    _realtimeSubscription?.cancel();
    try {
      _realtimeSubscription = Supabase.instance.client
          .from(SupabaseConstants.tableAppSettings)
          .stream(primaryKey: ['id'])
          .eq('id', 1)
          .listen(
            (data) {
              if (data.isNotEmpty) {
                final newSettings = AppSettingsModel.fromJson(data.first);
                state = state.copyWith(
                  settings: newSettings,
                  isOffline: false,
                );
                _saveToCache(newSettings);
              }
            },
            onError: (err) {
              debugPrint('Realtime app_settings subscription error: $err');
            },
          );
    } catch (e) {
      debugPrint('Failed to initialize realtime app_settings stream: $e');
    }
  }

  Future<void> _saveToCache(AppSettingsModel settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowWebsite, settings.showWebsite);
      if (settings.websiteUrl != null) {
        await prefs.setString(_keyWebsiteUrl, settings.websiteUrl!);
      } else {
        await prefs.remove(_keyWebsiteUrl);
      }
      if (settings.websiteTitle != null) {
        await prefs.setString(_keyWebsiteTitle, settings.websiteTitle!);
      } else {
        await prefs.remove(_keyWebsiteTitle);
      }
      await prefs.setString(_keyUpiId, settings.upiId);
      await prefs.setString(_keyPayeeName, settings.payeeName);
      await prefs.setBool(_keyIsUpiEnabled, settings.isUpiEnabled);
      if (settings.updatedAt != null) {
        await prefs.setString(_keyUpdatedAt, settings.updatedAt!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Failed saving app_settings to cache: $e');
    }
  }

  Future<void> refresh() async {
    try {
      final response = await Supabase.instance.client
          .from(SupabaseConstants.tableAppSettings)
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (response != null) {
        final newSettings = AppSettingsModel.fromJson(response);
        state = state.copyWith(settings: newSettings, isOffline: false);
        await _saveToCache(newSettings);
      }
    } catch (e) {
      state = state.copyWith(isOffline: true, error: e);
    }
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettingsState>(() {
  return AppSettingsNotifier();
});
