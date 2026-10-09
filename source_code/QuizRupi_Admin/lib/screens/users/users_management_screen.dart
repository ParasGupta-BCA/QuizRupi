import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../data/models/admin_models.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/users_admin_provider.dart';

class UsersManagementScreen extends ConsumerWidget {
  const UsersManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usersAsync = ref.watch(usersAdminListProvider);
    final dateFormat = DateFormat('dd MMM yyyy');

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
                        'Users Management',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      Text(
                        'View all registered customers, balance adjustments, and account suspension controls',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh Users',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(usersAdminListProvider),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by full name, email, or user code...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              onChanged: (val) {
                ref.read(userSearchProvider.notifier).state = val;
              },
            ),
            const SizedBox(height: 20),

            // Users List
            Expanded(
              child: usersAsync.when(
                loading: () => const SkeletonListLoader(count: 6),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error loading users: $err'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(usersAdminListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (users) {
                  if (users.isEmpty) {
                    return EmptyState(
                      icon: Icons.people_outline,
                      title: 'No Users Found',
                      message: 'No registered profiles match your search criteria.',
                    );
                  }

                  return Card(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final u = users[idx];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: u.isBlocked
                                ? AppColors.errorLight
                                : AppColors.primary.withValues(alpha: 0.15),
                            child: Icon(
                              u.isBlocked ? Icons.block : Icons.person,
                              color: u.isBlocked ? AppColors.error : AppColors.primary,
                              size: 18,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  u.fullName?.isNotEmpty == true ? u.fullName! : 'Student User',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Level ${u.level}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                              if (u.isBlocked) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Blocked',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 3),
                              Text(
                                '${u.email ?? "No Email"} • Code: ${u.userCode ?? "N/A"}',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 8,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.monetization_on, size: 13, color: AppColors.secondary),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${u.coinsBalance} Coins',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondaryDark, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '• Quizzes: ${u.quizzesPlayed} (${u.correctAnswers} correct)',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  Text(
                                    '• Joined: ${dateFormat.format(u.createdAt.toLocal())}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  visualDensity: VisualDensity.compact,
                                  minimumSize: const Size(0, 32),
                                ),
                                onPressed: () => _openCoinAdjustDialog(context, ref, u),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.toll_rounded, size: 14),
                                    SizedBox(width: 4),
                                    Text('Coins', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                tooltip: u.isBlocked ? 'Unblock User' : 'Block User',
                                icon: Icon(
                                  u.isBlocked ? Icons.check_circle_outline : Icons.block,
                                  color: u.isBlocked ? AppColors.success : AppColors.error,
                                  size: 18,
                                ),
                                onPressed: () => _toggleBlock(context, ref, u),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleBlock(BuildContext context, WidgetRef ref, UserModel user) {
    final willBlock = !user.isBlocked;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(willBlock ? 'Block User?' : 'Unblock User?'),
        content: Text(
          willBlock
              ? 'Are you sure you want to block ${user.fullName ?? user.email}? They will not be able to participate in quizzes or place orders.'
              : 'Restore full access for ${user.fullName ?? user.email}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminServiceProvider).toggleUserBlock(user.id, willBlock);
              ref.invalidate(usersAdminListProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: willBlock ? Colors.red : AppColors.success,
            ),
            child: Text(willBlock ? 'Block' : 'Unblock'),
          ),
        ],
      ),
    );
  }

  void _openCoinAdjustDialog(BuildContext context, WidgetRef ref, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => _CoinAdjustDialog(user: user),
    ).then((_) {
      ref.invalidate(usersAdminListProvider);
    });
  }
}

class _CoinAdjustDialog extends ConsumerStatefulWidget {
  final UserModel user;

  const _CoinAdjustDialog({required this.user});

  @override
  ConsumerState<_CoinAdjustDialog> createState() => _CoinAdjustDialogState();
}

class _CoinAdjustDialogState extends ConsumerState<_CoinAdjustDialog> {
  final _amountCtrl = TextEditingController(text: '100');
  final _reasonCtrl = TextEditingController(text: 'Admin bonus credit');
  String _type = 'credit'; // 'credit' or 'debit'
  bool _isSaving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(adminServiceProvider).adjustCoins(
            widget.user.id,
            amount,
            _type,
            _reasonCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to adjust coins: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.toll_rounded, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Coins for ${widget.user.fullName ?? widget.user.email ?? "User"}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance: ${widget.user.coinsBalance} Coins',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Add Coins (+)'),
                selected: _type == 'credit',
                selectedColor: AppColors.success.withValues(alpha: 0.15),
                onSelected: (_) => setState(() {
                  _type = 'credit';
                  _reasonCtrl.text = 'Admin bonus credit';
                }),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('Deduct Coins (-)'),
                selected: _type == 'debit',
                selectedColor: AppColors.error.withValues(alpha: 0.15),
                onSelected: (_) => setState(() {
                  _type = 'debit';
                  _reasonCtrl.text = 'Admin penalty / adjustment';
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount of Coins'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(labelText: 'Reason for Transaction'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _type == 'credit' ? AppColors.success : Colors.red,
          ),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_type == 'credit' ? 'Add Coins' : 'Deduct Coins'),
        ),
      ],
    );
  }
}
