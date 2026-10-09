import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/admin_models.dart';
import '../../providers/app_control_provider.dart';

class AppControlScreen extends ConsumerStatefulWidget {
  const AppControlScreen({super.key});

  @override
  ConsumerState<AppControlScreen> createState() => _AppControlScreenState();
}

class _AppControlScreenState extends ConsumerState<AppControlScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  late final TextEditingController _titleController;
  late final TextEditingController _upiController;
  late final TextEditingController _payeeNameController;
  late final TextEditingController _merchantCodeController;
  bool _showWebsite = false;
  bool _isUpiEnabled = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _titleController = TextEditingController();
    _upiController = TextEditingController();
    _payeeNameController = TextEditingController();
    _merchantCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _upiController.dispose();
    _payeeNameController.dispose();
    _merchantCodeController.dispose();
    super.dispose();
  }

  void _syncFromSettings(AppSettingsModel settings) {
    if (!_isInitialized) {
      _showWebsite = settings.showWebsite;
      _urlController.text = settings.websiteUrl ?? '';
      _titleController.text = settings.websiteTitle ?? '';
      _upiController.text = settings.upiId;
      _payeeNameController.text = settings.payeeName;
      _isUpiEnabled = settings.isUpiEnabled;
      _merchantCodeController.text = settings.merchantCode ?? '5499';
      _isInitialized = true;
    }
  }

  void _openWebsitePreview(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid https:// URL to preview.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(trimmed));

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 600,
            height: 700,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: AppColors.primary,
                  child: Row(
                    children: [
                      const Icon(Icons.preview_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'In-App Website Preview: $trimmed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: WebViewWidget(controller: controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveUpiSettings() async {
    final upi = _upiController.text.trim();
    final name = _payeeNameController.text.trim();
    final merchantCode = _merchantCodeController.text.trim();

    if (_isUpiEnabled) {
      if (upi.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UPI ID cannot be empty when UPI is enabled.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (!upi.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid UPI ID (e.g. quizrupi@upi).'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payee Name cannot be empty.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.payment_rounded, color: AppColors.secondaryDark),
            SizedBox(width: 8),
            Text('Confirm UPI Changes'),
          ],
        ),
        content: Text(
          'Are you sure you want to broadcast this UPI ID:\n\n'
          '• UPI ID: $upi\n'
          '• Payee Name: $name\n'
          '• Status: ${_isUpiEnabled ? "ENABLED" : "PAUSED"}\n\n'
          'All customer apps will receive these changes instantly in real-time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publish UPI ID'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(appControlProvider.notifier).savePaymentSettings(
        upiId: upi,
        payeeName: name,
        isUpiEnabled: _isUpiEnabled,
        merchantCode: merchantCode.isNotEmpty ? merchantCode : '5499',
      );
    }
  }

  void _testUpiIntent() async {
    final upi = _upiController.text.trim();
    final name = _payeeNameController.text.trim();
    if (upi.isEmpty || !upi.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid UPI ID (e.g. quizrupi@upi) to test.')),
      );
      return;
    }
    final uri = Uri.parse(
      'upi://pay?pa=$upi&pn=${Uri.encodeComponent(name.isNotEmpty ? name : "QuizRupi Store")}&am=1.00&cu=INR&tn=${Uri.encodeComponent("QuizRupi Test Transaction")}',
    );
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Generated UPI URI: $uri\n(Requires mobile device with UPI apps installed).')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('UPI URI: $uri\n(Note: Physical device with GPay/PhonePe required to launch native apps).')),
        );
      }
    }
  }

  Future<void> _confirmAndPublish() async {
    final url = _urlController.text.trim();
    final title = _titleController.text.trim();

    if (_showWebsite) {
      if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Website URL is required when Website Mode is ON.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      final uri = Uri.tryParse(url);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid URL. Only secure HTTPS URLs (https://...) are allowed.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _showWebsite ? Icons.warning_amber_rounded : Icons.info_outline,
              color: _showWebsite ? Colors.purple : AppColors.primary,
            ),
            const SizedBox(width: 10),
            const Text('Publish Real-Time Change?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _showWebsite
                  ? 'You are about to switch ALL active customer apps to WEBSITE MODE.'
                  : 'You are about to switch ALL active customer apps to STORE MODE.',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              _showWebsite
                  ? 'All users will immediately see full-screen "$url" without restarting the app.'
                  : 'All users will immediately see the full Quiz & UPSC/SSC Book Store without restarting the app.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _showWebsite ? Colors.purple : AppColors.primary,
            ),
            child: const Text('Yes, Publish Live'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(appControlProvider.notifier).saveAndPublish(
            showWebsite: _showWebsite,
            websiteUrl: url,
            websiteTitle: title,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controlState = ref.watch(appControlProvider);
    _syncFromSettings(controlState.settings);

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm:ss a');

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Remote App Mode & Website Switch',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(
                'Remotely control what all Super Quiz users see on their mobile phones in real-time via Supabase.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Feedback alerts
              if (controlState.successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          controlState.successMessage!,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.success),
                        onPressed: () => ref.read(appControlProvider.notifier).clearMessages(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (controlState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          controlState.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                        onPressed: () => ref.read(appControlProvider.notifier).clearMessages(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ==================== BIG TOGGLE CARD ====================
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _showWebsite ? Colors.purple : AppColors.primary,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: (_showWebsite ? Colors.purple : AppColors.primary)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _showWebsite ? Icons.language_rounded : Icons.storefront_rounded,
                              color: _showWebsite ? Colors.purple : AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _showWebsite ? 'SHOW WEBSITE (ON)' : 'SHOW STORE (OFF)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _showWebsite ? Colors.purple : AppColors.primary,
                                  ),
                                ),
                                Text(
                                  _showWebsite
                                      ? 'Fullscreen In-App Web View'
                                      : 'Native Quiz & Store View',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: _showWebsite,
                            // ignore: deprecated_member_use
                            activeColor: Colors.purple,
                            onChanged: (val) {
                              setState(() {
                                _showWebsite = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _showWebsite ? Icons.info_outline : Icons.check_circle_outline,
                              color: _showWebsite ? Colors.purple : AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _showWebsite
                                    ? 'ON = Users will see the website only. Store, quizzes, and bottom navigation are completely hidden.'
                                    : 'OFF = Users will see the store and quiz app (Home, Quiz Arena, Shop, and Orders).',
                                style: const TextStyle(fontSize: 13, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ==================== URL & TITLE CONFIGURATION ====================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Target Website Configuration',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Specify the exact HTTPS address and title loaded by the user app in website mode.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // URL Field
                      const Text(
                        'Website URL (Must start with https://)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _urlController,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          hintText: 'https://quizrupi.com',
                          prefixIcon: const Icon(Icons.link_rounded, size: 20),
                          suffixIcon: IconButton(
                            tooltip: 'Test Preview',
                            icon: const Icon(Icons.open_in_new, size: 20),
                            onPressed: () => _openWebsitePreview(_urlController.text),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Quick preset buttons
                      Wrap(
                        spacing: 8,
                        children: [
                          const Text('Quick test URLs:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          InkWell(
                            onTap: () => setState(() => _urlController.text = 'https://google.com'),
                            child: const Text('google.com', style: TextStyle(fontSize: 12, color: AppColors.primary, decoration: TextDecoration.underline)),
                          ),
                          InkWell(
                            onTap: () => setState(() => _urlController.text = 'https://flutter.dev'),
                            child: const Text('flutter.dev', style: TextStyle(fontSize: 12, color: AppColors.primary, decoration: TextDecoration.underline)),
                          ),
                          InkWell(
                            onTap: () => setState(() => _urlController.text = 'https://wikipedia.org'),
                            child: const Text('wikipedia.org', style: TextStyle(fontSize: 12, color: AppColors.primary, decoration: TextDecoration.underline)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Title Field
                      const Text(
                        'Website Title (Optional)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'QuizRupi Official Portal',
                          prefixIcon: Icon(Icons.title_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Buttons Row
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openWebsitePreview(_urlController.text),
                            icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                            label: const Text('Preview Website'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: controlState.isSaving ? null : _confirmAndPublish,
                              icon: controlState.isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                controlState.isSaving ? 'Publishing...' : 'Save & Publish Live',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _showWebsite ? Colors.purple : AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ==================== UPI PAYMENT GATEWAY REMOTE CONTROL ====================
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.secondary, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.secondaryDark, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'UPI Intent & Remote Payment Control',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Set the active UPI ID receiving customer payments from Google Pay, PhonePe, Paytm, etc.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isUpiEnabled,
                            activeColor: AppColors.secondary,
                            onChanged: (val) {
                              setState(() => _isUpiEnabled = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Live Preview Banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isUpiEnabled
                              ? AppColors.secondary.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isUpiEnabled
                                ? AppColors.secondary.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isUpiEnabled ? Icons.check_circle : Icons.pause_circle_outline,
                              color: _isUpiEnabled ? AppColors.secondaryDark : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _isUpiEnabled
                                    ? 'Live Payee VPA: ${_upiController.text.isNotEmpty ? _upiController.text : "quizrupi@upi"} (${_payeeNameController.text.isNotEmpty ? _payeeNameController.text : "QuizRupi Store"})'
                                    : 'UPI Payments are currently PAUSED for all customer apps.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: _isUpiEnabled ? AppColors.secondaryDark : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // VPA Input
                      const Text(
                        'Active UPI ID / Payee VPA (Virtual Payment Address)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _upiController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'e.g. quizrupi@upi, yourstore@okhdfcbank',
                          prefixIcon: const Icon(Icons.alternate_email, size: 20),
                          suffixIcon: IconButton(
                            tooltip: 'Copy UPI ID',
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _upiController.text.trim()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('UPI ID copied to clipboard')),
                              );
                            },
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      // Payee Name
                      const Text(
                        'Payee / Business Name (Shown in customer UPI apps)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _payeeNameController,
                        decoration: const InputDecoration(
                          hintText: 'QuizRupi Store',
                          prefixIcon: Icon(Icons.business_rounded, size: 20),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      // Quick Presets
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('Presets:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          InkWell(
                            onTap: () => setState(() => _upiController.text = 'quizrupi@upi'),
                            child: const Text('quizrupi@upi', style: TextStyle(fontSize: 12, color: AppColors.primary, decoration: TextDecoration.underline)),
                          ),
                          InkWell(
                            onTap: () => setState(() => _upiController.text = 'quizrupi@okaxis'),
                            child: const Text('quizrupi@okaxis', style: TextStyle(fontSize: 12, color: AppColors.primary, decoration: TextDecoration.underline)),
                          ),
                          InkWell(
                            onTap: () => setState(() => _upiController.text = 'quizrupi@paytm'),
                            child: const Text('quizrupi@paytm', style: TextStyle(fontSize: 12, color: AppColors.primary, decoration: TextDecoration.underline)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Action Buttons Row
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _testUpiIntent,
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text('Test UPI Intent'),
                            style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                          ),
                          ElevatedButton.icon(
                            onPressed: controlState.isSaving ? null : _saveUpiSettings,
                            icon: const Icon(Icons.save_rounded, size: 16),
                            label: const Text('Save & Publish UPI ID'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.black,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ==================== LIVE STATUS & LAST UPDATED ====================
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.sensors, color: AppColors.success, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Real-Time Channel',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Supabase Realtime active (Instant client dispatch)',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.history_toggle_off, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Last Updated At',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    controlState.settings.updatedAt != null
                                        ? dateFormat.format(controlState.settings.updatedAt!.toLocal())
                                        : 'Never modified',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ==================== CHANGE HISTORY AUDIT LOG ====================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Audit Log & Change History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${controlState.history.length} records',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (controlState.history.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text(
                            'No changes recorded yet.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Whenever you toggle modes or update URLs, Postgres triggers automatically log it here.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controlState.history.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final item = controlState.history[idx];
                      final wasOn = item.oldShowWebsite ?? false;
                      final isNowOn = item.newShowWebsite ?? false;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isNowOn
                              ? Colors.purple.withValues(alpha: 0.15)
                              : AppColors.success.withValues(alpha: 0.15),
                          child: Icon(
                            isNowOn ? Icons.language : Icons.storefront,
                            color: isNowOn ? Colors.purple : AppColors.success,
                            size: 18,
                          ),
                        ),
                        title: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              isNowOn ? 'Website Mode Enabled' : 'Store Mode Enabled',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isNowOn != wasOn) ? Colors.blue.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isNowOn != wasOn ? 'Mode Switch' : 'URL Update',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isNowOn != wasOn ? AppColors.primary : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              item.newWebsiteUrl != null && item.newWebsiteUrl!.isNotEmpty
                                  ? 'URL: ${item.newWebsiteUrl}'
                                  : 'URL: (None / Store Default)',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              dateFormat.format(item.changedAt.toLocal()),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.verified_outlined, size: 16, color: AppColors.success),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
