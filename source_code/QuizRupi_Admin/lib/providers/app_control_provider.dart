import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/admin_models.dart';
import 'admin_auth_provider.dart';

class AppControlState {
  final AppSettingsModel settings;
  final List<AppSettingsHistoryModel> history;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const AppControlState({
    this.settings = const AppSettingsModel(),
    this.history = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  AppControlState copyWith({
    AppSettingsModel? settings,
    List<AppSettingsHistoryModel>? history,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return AppControlState(
      settings: settings ?? this.settings,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class AppControlNotifier extends Notifier<AppControlState> {
  StreamSubscription<AppSettingsModel>? _subscription;

  @override
  AppControlState build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });

    _init();
    return const AppControlState(isLoading: true);
  }

  Future<void> _init() async {
    final service = ref.read(adminServiceProvider);
    try {
      final initialSettings = await service.getAppSettings();
      final history = await service.getAppSettingsHistory();

      state = state.copyWith(
        settings: initialSettings,
        history: history,
        isLoading: false,
      );

      // Start Realtime stream
      _subscription = service.streamAppSettings().listen((settings) async {
        final freshHistory = await service.getAppSettingsHistory();
        state = state.copyWith(settings: settings, history: freshHistory);
      }, onError: (err) {
        debugPrint('AppControl stream error: $err');
      });
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> saveAndPublish({
    required bool showWebsite,
    required String websiteUrl,
    required String websiteTitle,
  }) async {
    final trimmedUrl = websiteUrl.trim();

    // Validation
    if (showWebsite) {
      if (trimmedUrl.isEmpty) {
        state = state.copyWith(errorMessage: 'Website URL cannot be empty when Website Mode is ON.');
        return false;
      }
      final uri = Uri.tryParse(trimmedUrl);
      if (uri == null || !uri.hasScheme || uri.scheme != 'https' || uri.host.isEmpty) {
        state = state.copyWith(
          errorMessage: 'Invalid URL. Only valid HTTPS URLs (e.g. https://quizrupi.com) are allowed.',
        );
        return false;
      }
    }

    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);

    try {
      final service = ref.read(adminServiceProvider);
      await service.updateAppSettings(
        showWebsite: showWebsite,
        websiteUrl: trimmedUrl.isNotEmpty ? trimmedUrl : null,
        websiteTitle: websiteTitle.trim().isNotEmpty ? websiteTitle.trim() : null,
      );

      final freshHistory = await service.getAppSettingsHistory();
      final freshSettings = await service.getAppSettings();

      state = state.copyWith(
        isSaving: false,
        settings: freshSettings,
        history: freshHistory,
        successMessage: showWebsite
            ? 'Website Mode published! All users will now see the website in real-time.'
            : 'Store Mode published! All users will now see the store in real-time.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to publish changes: $e',
      );
      return false;
    }
  }

  Future<bool> quickToggleMode(bool newShowWebsite) async {
    final currentUrl = state.settings.websiteUrl ?? '';
    if (newShowWebsite && (currentUrl.isEmpty || !currentUrl.startsWith('https://'))) {
      state = state.copyWith(
        errorMessage: 'Cannot enable Website Mode: No valid HTTPS URL is configured.',
      );
      return false;
    }

    return await saveAndPublish(
      showWebsite: newShowWebsite,
      websiteUrl: currentUrl,
      websiteTitle: state.settings.websiteTitle ?? '',
    );
  }

  Future<bool> savePaymentSettings({
    required String upiId,
    required String payeeName,
    required bool isUpiEnabled,
    String? merchantCode,
  }) async {
    final trimmedUpi = upiId.trim();
    final trimmedName = payeeName.trim();

    if (isUpiEnabled) {
      if (trimmedUpi.isEmpty) {
        state = state.copyWith(errorMessage: 'UPI ID cannot be empty.');
        return false;
      }
      if (!trimmedUpi.contains('@')) {
        state = state.copyWith(
          errorMessage: 'Invalid UPI ID format. Must be in username@bank format (e.g. quizrupi@upi).',
        );
        return false;
      }
      if (trimmedName.isEmpty) {
        state = state.copyWith(errorMessage: 'Payee Name cannot be empty.');
        return false;
      }
    }

    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);

    try {
      final service = ref.read(adminServiceProvider);
      await service.updatePaymentSettings(
        upiId: trimmedUpi,
        payeeName: trimmedName,
        isUpiEnabled: isUpiEnabled,
        merchantCode: merchantCode,
      );

      final freshSettings = await service.getAppSettings();
      state = state.copyWith(
        isSaving: false,
        settings: freshSettings,
        successMessage: 'UPI ID "$trimmedUpi" published! Customer apps are now synced in real-time.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to update UPI settings: $e',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

final appControlProvider = NotifierProvider<AppControlNotifier, AppControlState>(() {
  return AppControlNotifier();
});
