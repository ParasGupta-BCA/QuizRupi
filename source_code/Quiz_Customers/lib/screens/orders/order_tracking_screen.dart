import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/order_provider.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  Timer? _tickerTimer;
  int _startTimeMs = 0;
  int _elapsedSeconds = 0;
  int? _lastCelebratedStep;

  // Realistic delivery progression thresholds (in seconds)
  static const int kPackedThresholdSeconds = 12;
  static const int kInTransitThresholdSeconds = 30;
  static const int kOutForDeliveryThresholdSeconds = 55;

  @override
  void initState() {
    super.initState();
    _initTrackingTime();
    _startTicker();
  }

  Future<void> _initTrackingTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'order_tracking_start_${widget.orderId}';
      int? saved = prefs.getInt(key);
      if (saved == null) {
        saved = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt(key, saved);
      }
      if (mounted) {
        setState(() {
          _startTimeMs = saved!;
          _elapsedSeconds = ((DateTime.now().millisecondsSinceEpoch - _startTimeMs) / 1000).floor();
          _lastCelebratedStep = _getStepNumber(_elapsedSeconds);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _startTimeMs = DateTime.now().millisecondsSinceEpoch;
          _elapsedSeconds = 0;
          _lastCelebratedStep = 1;
        });
      }
    }
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_startTimeMs > 0) {
        final elapsed = ((DateTime.now().millisecondsSinceEpoch - _startTimeMs) / 1000).floor();
        final currentStep = _getStepNumber(elapsed);

        // When a new stage ticks, give a pleasant tactile haptic feedback
        if (_lastCelebratedStep != null && currentStep > _lastCelebratedStep!) {
          HapticFeedback.lightImpact();
        }
        _lastCelebratedStep = currentStep;

        setState(() {
          _elapsedSeconds = elapsed;
        });
      }
    });
  }

  int _getStepNumber(int elapsed) {
    if (elapsed >= kOutForDeliveryThresholdSeconds) return 4;
    if (elapsed >= kInTransitThresholdSeconds) return 3;
    if (elapsed >= kPackedThresholdSeconds) return 2;
    return 1;
  }

  Future<void> _resetTrackingDemo() async {
    HapticFeedback.mediumImpact();
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'order_tracking_start_${widget.orderId}';
      await prefs.setInt(key, now);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _startTimeMs = now;
        _elapsedSeconds = 0;
        _lastCelebratedStep = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.sync_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Live tracking feed re-synced to step 1!'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.primaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Track Package',
          style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppColors.onSurfaceVariant),
            tooltip: 'Re-sync Live Tracking',
            onPressed: _resetTrackingDemo,
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) {
          final trackingId = order?.trackingId ?? 'EK-299042IN';
          final estDate = order?.estimatedDeliveryDate ?? DateTime.now().add(const Duration(days: 4));
          final dateStr = DateFormat('EEEE, d MMMM').format(estDate);
          final orderItems = order?.items ?? [];

          final isDelivered = order?.status.toLowerCase() == 'delivered';

          // Step 1: Order Confirmed
          const bool step1Completed = true;
          const bool step1Current = false;

          // Step 2: Packed & Ready to Ship
          final bool step2Completed = isDelivered || _elapsedSeconds >= kPackedThresholdSeconds;
          final bool step2Current = !step2Completed && _elapsedSeconds < kPackedThresholdSeconds;

          // Step 3: In Transit
          final bool step3Completed = isDelivered || _elapsedSeconds >= kInTransitThresholdSeconds;
          final bool step3Current = !step3Completed && _elapsedSeconds >= kPackedThresholdSeconds;

          // Step 4: Out for Delivery
          final bool step4Completed = isDelivered || _elapsedSeconds >= kOutForDeliveryThresholdSeconds;
          final bool step4Current = !step4Completed && _elapsedSeconds >= kInTransitThresholdSeconds;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRACKING NUMBER',
                                style: AppTextStyles.labelSm.copyWith(color: AppColors.outline, fontSize: 10),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                trackingId,
                                style: AppTextStyles.headlineSm.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryContainer,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ON SCHEDULE',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.emeraldGreen,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.local_shipping, color: AppColors.secondary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Estimated Delivery by $dateStr',
                              style: AppTextStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Carrier: QuizRupi Express Logistics (Surface)',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.outline, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Vertical Status Stepper Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery Progress',
                      style: AppTextStyles.headlineSm.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryContainer.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.emeraldGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Live Tracking',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.primaryFixed,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Vertical Status Stepper Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      // Step 1: Order Confirmed
                      _buildTrackingStep(
                        title: 'Order Confirmed',
                        subtitle: 'Payment verified and sent to dispatch warehouse',
                        time: 'Completed',
                        isCompleted: step1Completed,
                        isCurrent: step1Current,
                        showLine: true,
                        lineCompleted: step2Completed,
                      ),

                      // Step 2: Packed & Ready to Ship
                      _buildTrackingStep(
                        title: 'Packed & Ready to Ship',
                        subtitle: step2Completed
                            ? 'Inspection completed, packed in moisture-proof cover'
                            : 'Inspection in progress at central dispatch warehouse',
                        time: step2Completed ? 'Completed' : 'In Progress',
                        isCompleted: step2Completed,
                        isCurrent: step2Current,
                        showLine: true,
                        lineCompleted: step3Completed,
                      ),

                      // Step 3: In Transit
                      _buildTrackingStep(
                        title: 'In Transit',
                        subtitle: step3Completed
                            ? 'Dispatched from Central Hub, on route to destination'
                            : (step3Current
                                ? 'Arrived at Central Fulfillment Center, New Delhi'
                                : 'Courier pickup scheduled with QuizRupi Express'),
                        time: step3Completed ? 'Completed' : (step3Current ? 'In Progress' : 'Upcoming'),
                        isCompleted: step3Completed,
                        isCurrent: step3Current,
                        showLine: true,
                        lineCompleted: step4Completed,
                      ),

                      // Step 4: Out for Delivery
                      _buildTrackingStep(
                        title: 'Out for Delivery',
                        subtitle: step4Completed
                            ? 'Package is out for doorstep delivery today'
                            : (step4Current
                                ? 'Assigned to delivery executive (Rahul • Surface Logistics)'
                                : 'Delivery executive will deliver to your doorstep'),
                        time: step4Completed
                            ? 'Out for Delivery'
                            : (step4Current ? 'Arriving Today' : 'Expected by $dateStr'),
                        isCompleted: step4Completed,
                        isCurrent: step4Current,
                        showLine: false,
                        lineCompleted: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Destination Address Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.primaryContainer, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Shipping Destination',
                            style: AppTextStyles.headlineSm.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        order?.deliveryAddress ?? '123, Green Park, Hauz Khas, New Delhi - 110016',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Items in this package
                if (orderItems.isNotEmpty) ...[
                  Text(
                    'Package Contents (${orderItems.length} items)',
                    style: AppTextStyles.headlineSm.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  ...orderItems.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.menu_book, color: AppColors.primaryContainer, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.book?.title ?? 'Quiz Book',
                                    style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Quantity: ${item.quantity} • ₹${item.priceAtPurchase.toInt()}',
                                    style: AppTextStyles.bodySm.copyWith(color: AppColors.outline),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 20),

                // Support button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contact support via WhatsApp or email: support@quizrupi.app')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.support_agent, size: 20),
                    label: Text(
                      'Need Help with this Shipment?',
                      style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer)),
        error: (err, _) => Center(child: Text('Error loading order: $err')),
      ),
    );
  }

  Widget _buildTrackingStep({
    required String title,
    required String subtitle,
    required String time,
    required bool isCompleted,
    required bool isCurrent,
    required bool showLine,
    required bool lineCompleted,
  }) {
    final stepColor = isCurrent
        ? AppColors.secondary
        : (isCompleted ? AppColors.emeraldGreen : AppColors.outlineVariant);

    final showCheck = isCompleted || isCurrent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.emeraldGreen
                    : (isCurrent ? AppColors.secondary : AppColors.surfaceContainerHigh),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent
                      ? AppColors.secondary
                      : (isCompleted ? AppColors.emeraldGreen : Colors.transparent),
                  width: 2,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : (isCompleted
                        ? [
                            BoxShadow(
                              color: AppColors.emeraldGreen.withOpacity(0.3),
                              blurRadius: 6,
                            ),
                          ]
                        : null),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: showCheck
                      ? const Icon(
                          Icons.check,
                          key: ValueKey('check'),
                          color: Colors.white,
                          size: 14,
                        )
                      : Container(
                          key: const ValueKey('dot'),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.outline,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ),
            ),
            if (showLine)
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 2,
                height: 42,
                color: lineCompleted
                    ? AppColors.emeraldGreen.withOpacity(0.7)
                    : AppColors.outlineVariant.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelMd.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isCurrent ? AppColors.secondary : AppColors.onSurface,
                      ),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 400),
                      style: AppTextStyles.labelSm.copyWith(
                        fontSize: 10,
                        color: stepColor,
                        fontWeight: FontWeight.w700,
                      ),
                      child: Text(time),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 400),
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  child: Text(subtitle),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
