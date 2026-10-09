import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../data/models/admin_models.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/orders_admin_provider.dart';

class OrdersManagementScreen extends ConsumerWidget {
  const OrdersManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordersAsync = ref.watch(ordersAdminListProvider);
    final currentStatus = ref.watch(orderStatusFilterProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    final statuses = ['All', 'Placed', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled'];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Orders',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      Text(
                        'Track customer purchases, update shipping statuses, tracking numbers & delivery estimates',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh Orders',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(ordersAdminListProvider),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statuses.map((status) {
                  final isSelected = status == currentStatus;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(status),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : null,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        ref.read(orderStatusFilterProvider.notifier).state = status;
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by Order ID, customer name or email...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onChanged: (val) {
                ref.read(orderSearchProvider.notifier).state = val;
              },
            ),
            const SizedBox(height: 20),

            // Orders Table / List
            Expanded(
              child: ordersAsync.when(
                loading: () => const SkeletonListLoader(count: 6),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error loading orders: $err'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(ordersAdminListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (orders) {
                  if (orders.isEmpty) {
                    return EmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'No Orders Found',
                      message: 'No customer orders match the current status filter or search query.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final order = orders[idx];
                      return Card(
                        elevation: 1,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: _getStatusColor(order.status).withValues(alpha: 0.15),
                                    child: Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status), size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Placed on ${dateFormat.format(order.createdAt.toLocal())}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      order.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(order.status),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    currency.format(order.totalAmount),
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primary),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Customer: ${order.customerName ?? order.customerEmail ?? "Anonymous"}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Payment: ${order.paymentMethod}' +
                                              (order.trackingId != null ? ' • Tracking: ${order.trackingId}' : ''),
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _openOrderDetails(context, ref, order),
                                    icon: const Icon(Icons.edit_note, size: 16),
                                    label: const Text('Manage'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Placed':
        return Colors.blue;
      case 'Shipped':
        return Colors.orange;
      case 'Out for Delivery':
        return Colors.deepPurple;
      case 'Delivered':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Placed':
        return Icons.receipt_long;
      case 'Shipped':
        return Icons.local_shipping;
      case 'Out for Delivery':
        return Icons.directions_bike;
      case 'Delivered':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.shopping_bag;
    }
  }

  void _openOrderDetails(BuildContext context, WidgetRef ref, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => _OrderDetailsDialog(order: order),
    ).then((_) {
      ref.invalidate(ordersAdminListProvider);
    });
  }
}

class _OrderDetailsDialog extends ConsumerStatefulWidget {
  final OrderModel order;

  const _OrderDetailsDialog({required this.order});

  @override
  ConsumerState<_OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends ConsumerState<_OrderDetailsDialog> {
  late String _status;
  late final TextEditingController _trackingCtrl;
  DateTime? _estimatedDeliveryDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order.status;
    _trackingCtrl = TextEditingController(text: widget.order.trackingId ?? '');
    _estimatedDeliveryDate = widget.order.estimatedDeliveryDate;
  }

  @override
  void dispose() {
    _trackingCtrl.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(adminServiceProvider).updateOrderStatus(
            widget.order.id,
            _status,
            trackingId: _trackingCtrl.text.trim().isNotEmpty ? _trackingCtrl.text.trim() : null,
            estimatedDeliveryDate: _estimatedDeliveryDate,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${widget.order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer info
                      const Text('Customer & Shipping Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Name: ${widget.order.customerName ?? "Not specified"}'),
                      Text('Email: ${widget.order.customerEmail ?? "Not specified"}'),
                      if (widget.order.deliveryAddress != null)
                        Text('Address: ${widget.order.deliveryAddress}'),
                      const SizedBox(height: 16),

                      // Order Items
                      const Text('Items in Order', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...widget.order.items.map((it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                const Icon(Icons.book, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${it.bookTitle ?? "Book"} (Qty: ${it.quantity})',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  currency.format(it.priceAtPurchase * it.quantity),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 24),

                      // Payment summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount Paid:'),
                          Text(
                            currency.format(widget.order.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Status Updater Form
                      const Text('Update Order Fulfillment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Order Status'),
                        items: const [
                          DropdownMenuItem(value: 'Placed', child: Text('Placed')),
                          DropdownMenuItem(value: 'Shipped', child: Text('Shipped')),
                          DropdownMenuItem(value: 'Out for Delivery', child: Text('Out for Delivery')),
                          DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                          DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                        ],
                        onChanged: (v) => setState(() => _status = v ?? _status),
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _trackingCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Courier Tracking ID (e.g. DTDC / Delhivery / Bluedart)',
                          hintText: 'e.g. DEL7891230491',
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Estimated delivery date picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Estimated Delivery Date'),
                        subtitle: Text(
                          _estimatedDeliveryDate != null
                              ? dateFormat.format(_estimatedDeliveryDate!)
                              : 'Not set yet',
                        ),
                        trailing: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _estimatedDeliveryDate ?? DateTime.now().add(const Duration(days: 3)),
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setState(() => _estimatedDeliveryDate = picked);
                            }
                          },
                          child: const Text('Select Date'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _update,
                    child: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Order Updates'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
