import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../data/models/admin_models.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/quiz_admin_provider.dart';

class QuizManagementScreen extends ConsumerStatefulWidget {
  const QuizManagementScreen({super.key});

  @override
  ConsumerState<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends ConsumerState<QuizManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quiz Content & Challenges',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                Text(
                  'Manage question banks, categories, CSV bulk imports, and daily challenge rotations',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  tabs: const [
                    Tab(icon: Icon(Icons.help_outline, size: 18), text: 'Questions Bank'),
                    Tab(icon: Icon(Icons.category_outlined, size: 18), text: 'Categories'),
                    Tab(icon: Icon(Icons.today_outlined, size: 18), text: 'Daily Challenges'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQuestionsTab(context, ref, isDark),
                  _buildCategoriesTab(context, ref, isDark),
                  _buildDailyChallengesTab(context, ref, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 1: QUESTIONS ====================
  Widget _buildQuestionsTab(BuildContext context, WidgetRef ref, bool isDark) {
    final questionsAsync = ref.watch(questionsAdminListProvider);
    final categoriesAsync = ref.watch(quizCategoriesProvider);
    final currentCat = ref.watch(questionCategoryFilterProvider);

    return Column(
      children: [
        // Action Bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search questions by text...',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (v) => ref.read(questionSearchProvider.notifier).state = v,
                  ),
                ),
                const SizedBox(width: 10),
                categoriesAsync.maybeWhen(
                  data: (cats) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentCat,
                        items: [
                          const DropdownMenuItem(value: 'All', child: Text('All')),
                          ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (v) {
                          if (v != null) ref.read(questionCategoryFilterProvider.notifier).state = v;
                        },
                      ),
                    ),
                  ),
                  orElse: () => const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _importQuestionsFromCsv,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Bulk CSV Import'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openQuestionEditor(context, ref, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Question'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Questions List
        Expanded(
          child: questionsAsync.when(
            loading: () => const SkeletonListLoader(count: 6),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (questions) {
              if (questions.isEmpty) {
                return EmptyState(
                  icon: Icons.help_outline,
                  title: 'No Questions Found',
                  message: 'No quiz questions found matching the filter.',
                  actionLabel: 'Add Question',
                  onAction: () => _openQuestionEditor(context, ref, null),
                );
              }

              return Card(
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: questions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final q = questions[idx];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      title: Text(
                        q.questionText,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildOptionPill('A', q.optionA, q.correctOption == 'A'),
                              _buildOptionPill('B', q.optionB, q.correctOption == 'B'),
                              _buildOptionPill('C', q.optionC, q.correctOption == 'C'),
                              _buildOptionPill('D', q.optionD, q.correctOption == 'D'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Category: ${q.categoryName ?? "General"} • Difficulty: ${q.difficulty} • Limit: ${q.timeLimitSeconds}s',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (q.imageUrl != null) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.image, size: 14, color: AppColors.primary),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _openQuestionEditor(context, ref, q),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () => _deleteQuestion(context, ref, q),
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
    );
  }

  Widget _buildOptionPill(String opt, String text, bool isCorrect) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.success.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCorrect ? AppColors.success : Colors.transparent,
          width: 1,
        ),
      ),
      child: Text(
        '$opt: $text',
        style: TextStyle(
          fontSize: 11,
          fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
          color: isCorrect ? AppColors.success : null,
        ),
      ),
    );
  }

  // ==================== TAB 2: CATEGORIES ====================
  Widget _buildCategoriesTab(BuildContext context, WidgetRef ref, bool isDark) {
    final categoriesAsync = ref.watch(quizCategoriesProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () => _openCategoryEditor(context, ref, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Category'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: categoriesAsync.when(
            loading: () => const SkeletonListLoader(count: 5),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (cats) {
              return Card(
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: cats.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final cat = cats[idx];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: const Icon(Icons.extension, color: AppColors.primary, size: 18),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              cat.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (cat.isNew) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                              child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        'Difficulty: ${cat.difficulty} • ${cat.mcqCount} Questions in Bank',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _openCategoryEditor(context, ref, cat),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () => _deleteCategory(context, ref, cat),
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
    );
  }

  // ==================== TAB 3: DAILY CHALLENGES ====================
  Widget _buildDailyChallengesTab(BuildContext context, WidgetRef ref, bool isDark) {
    final challengesAsync = ref.watch(dailyChallengesAdminProvider);
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy');

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Configured Daily Challenges',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _openDailyChallengeScheduler(context, ref),
              icon: const Icon(Icons.event_available, size: 18),
              label: const Text('Schedule Date Challenge'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: challengesAsync.when(
            loading: () => const SkeletonListLoader(count: 4),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (challenges) {
              if (challenges.isEmpty) {
                return EmptyState(
                  icon: Icons.event,
                  title: 'No Challenges Scheduled',
                  message: 'Schedule daily challenges for upcoming dates with custom bonus coins.',
                  actionLabel: 'Schedule Now',
                  onAction: () => _openDailyChallengeScheduler(context, ref),
                );
              }

              return Card(
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: challenges.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final ch = challenges[idx];
                    final date = DateTime.tryParse(ch['date'].toString()) ?? DateTime.now();
                    final catName = ch['quiz_categories']?['name'] ?? 'General';
                    final bonus = ch['bonus_coins'] ?? 50;
                    final total = ch['total_questions'] ?? 10;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                            child: const Icon(Icons.emoji_events, color: AppColors.secondaryDark, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      dateFormat.format(date),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '+$bonus Bonus Coins',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondaryDark,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Category: $catName • Total Questions: $total',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
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
    );
  }

  // ==================== CSV BULK IMPORT ====================
  Future<void> _importQuestionsFromCsv() async {
    final categories = await ref.read(adminServiceProvider).getCategories();
    if (categories.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one category first.')));
      return;
    }

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result.isNotEmpty) {
      final file = result.first;
      try {
        final bytes = await file.readAsBytes();
        final content = utf8.decode(bytes);
        final rows = csv.decode(content);

        if (rows.length < 2) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV file is empty or missing headers.')));
          return;
        }

          // Expected headers: question, option_a, option_b, option_c, option_d, correct_option, explanation, difficulty
          final defaultCatId = categories.first.id;
          final List<QuestionModel> questionsToInsert = [];

          for (int i = 1; i < rows.length; i++) {
            final row = rows[i];
            if (row.length < 6) continue;
            final qText = row[0].toString().trim();
            final optA = row[1].toString().trim();
            final optB = row[2].toString().trim();
            final optC = row[3].toString().trim();
            final optD = row[4].toString().trim();
            final correct = row[5].toString().trim().toUpperCase();
            final explanation = row.length > 6 ? row[6].toString().trim() : null;
            final diff = row.length > 7 ? row[7].toString().trim() : 'Medium';

            if (qText.isNotEmpty && optA.isNotEmpty) {
              questionsToInsert.add(QuestionModel(
                id: '',
                categoryId: defaultCatId,
                questionText: qText,
                optionA: optA,
                optionB: optB,
                optionC: optC,
                optionD: optD,
                correctOption: correct,
                explanationText: explanation,
                difficulty: diff,
                createdAt: DateTime.now(),
              ));
            }
          }

          if (questionsToInsert.isNotEmpty) {
            final count = await ref.read(adminServiceProvider).bulkImportQuestions(questionsToInsert);
            ref.invalidate(questionsAdminListProvider);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Successfully imported $count questions from CSV!'), backgroundColor: AppColors.success),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV Import Error: $e'), backgroundColor: AppColors.error));
          }
        }
      }
    }
  }

  // ==================== QUESTION EDITOR ====================
  void _openQuestionEditor(BuildContext context, WidgetRef ref, QuestionModel? question) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _QuestionEditorDialog(question: question),
    ).then((_) => ref.invalidate(questionsAdminListProvider));
  }

  void _deleteQuestion(BuildContext context, WidgetRef ref, QuestionModel q) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question?'),
        content: Text('Delete "${q.questionText}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminServiceProvider).deleteQuestion(q.id);
              ref.invalidate(questionsAdminListProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ==================== CATEGORY EDITOR ====================
  void _openCategoryEditor(BuildContext context, WidgetRef ref, QuizCategoryModel? cat) {
    final nameCtrl = TextEditingController(text: cat?.name ?? '');
    String diff = cat?.difficulty ?? 'Medium';
    bool isNew = cat?.isNew ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text(cat == null ? 'Add Category' : 'Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Category Name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: diff,
                decoration: const InputDecoration(labelText: 'Difficulty'),
                items: const [
                  DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'Hard', child: Text('Hard')),
                ],
                onChanged: (v) => setDState(() => diff = v ?? 'Medium'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(value: isNew, onChanged: (v) => setDState(() => isNew = v ?? false)),
                  const Text('Mark as New'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final service = ref.read(adminServiceProvider);
                if (cat == null) {
                  await service.createCategory(QuizCategoryModel(
                    id: '',
                    name: nameCtrl.text.trim(),
                    difficulty: diff,
                    isNew: isNew,
                    createdAt: DateTime.now(),
                  ));
                } else {
                  await service.updateCategory(QuizCategoryModel(
                    id: cat.id,
                    name: nameCtrl.text.trim(),
                    difficulty: diff,
                    isNew: isNew,
                    createdAt: cat.createdAt,
                  ));
                }
                ref.invalidate(quizCategoriesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCategory(BuildContext context, WidgetRef ref, QuizCategoryModel cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Delete "${cat.name}" and all questions in it?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminServiceProvider).deleteCategory(cat.id);
              ref.invalidate(quizCategoriesProvider);
              ref.invalidate(questionsAdminListProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ==================== DAILY CHALLENGE SCHEDULER ====================
  void _openDailyChallengeScheduler(BuildContext context, WidgetRef ref) async {
    final categories = await ref.read(adminServiceProvider).getCategories();
    if (categories.isEmpty) return;

    DateTime selectedDate = DateTime.now();
    String categoryId = categories.first.id;
    final bonusCtrl = TextEditingController(text: '50');
    final totalCtrl = TextEditingController(text: '10');

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Schedule Daily Challenge'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                trailing: TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 7)),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (d != null) setDState(() => selectedDate = d);
                  },
                  child: const Text('Change Date'),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setDState(() => categoryId = v ?? categoryId),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: bonusCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Bonus Coins Awarded'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: totalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Questions'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final bonus = int.tryParse(bonusCtrl.text) ?? 50;
                final total = int.tryParse(totalCtrl.text) ?? 10;
                await ref.read(adminServiceProvider).setDailyChallenge(selectedDate, categoryId, bonus, total);
                ref.invalidate(dailyChallengesAdminProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Schedule Challenge'),
            ),
          ],
        ),
      ),
    );
  }

class _QuestionEditorDialog extends ConsumerStatefulWidget {
  final QuestionModel? question;

  const _QuestionEditorDialog({this.question});

  @override
  ConsumerState<_QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends ConsumerState<_QuestionEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qCtrl;
  late final TextEditingController _optACtrl;
  late final TextEditingController _optBCtrl;
  late final TextEditingController _optCCtrl;
  late final TextEditingController _optDCtrl;
  late final TextEditingController _expCtrl;
  String? _categoryId;
  String _correctOption = 'A';
  String _difficulty = 'Medium';
  int _timeLimit = 15;
  String? _imageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _qCtrl = TextEditingController(text: q?.questionText ?? '');
    _optACtrl = TextEditingController(text: q?.optionA ?? '');
    _optBCtrl = TextEditingController(text: q?.optionB ?? '');
    _optCCtrl = TextEditingController(text: q?.optionC ?? '');
    _optDCtrl = TextEditingController(text: q?.optionD ?? '');
    _expCtrl = TextEditingController(text: q?.explanationText ?? '');
    _categoryId = q?.categoryId;
    _correctOption = q?.correctOption ?? 'A';
    _difficulty = q?.difficulty ?? 'Medium';
    _timeLimit = q?.timeLimitSeconds ?? 15;
    _imageUrl = q?.imageUrl;
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _optACtrl.dispose();
    _optBCtrl.dispose();
    _optCCtrl.dispose();
    _optDCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  Future<void> _uploadImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isNotEmpty) {
      final file = result.first;
      setState(() => _isSaving = true);
      try {
        final bytes = await file.readAsBytes();
        final url = await ref.read(adminServiceProvider).uploadImage(
              bytes,
              file.name,
              SupabaseConstants.bucketQuestionImages,
            );
        setState(() {
          _imageUrl = url;
          _isSaving = false;
        });
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a category')));
      return;
    }

    setState(() => _isSaving = true);
    final service = ref.read(adminServiceProvider);

    final model = QuestionModel(
      id: widget.question?.id ?? '',
      categoryId: _categoryId!,
      questionText: _qCtrl.text.trim(),
      imageUrl: _imageUrl,
      optionA: _optACtrl.text.trim(),
      optionB: _optBCtrl.text.trim(),
      optionC: _optCCtrl.text.trim(),
      optionD: _optDCtrl.text.trim(),
      correctOption: _correctOption,
      explanationText: _expCtrl.text.trim().isNotEmpty ? _expCtrl.text.trim() : null,
      difficulty: _difficulty,
      timeLimitSeconds: _timeLimit,
      createdAt: DateTime.now(),
    );

    try {
      if (widget.question == null) {
        await service.createQuestion(model);
      } else {
        await service.updateQuestion(model);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(quizCategoriesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.question == null ? 'Add Question' : 'Edit Question',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        catsAsync.maybeWhen(
                          data: (cats) {
                            _categoryId ??= cats.isNotEmpty ? cats.first.id : null;
                            return DropdownButtonFormField<String>(
                              value: _categoryId,
                              decoration: const InputDecoration(labelText: 'Category *'),
                              items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                              onChanged: (v) => setState(() => _categoryId = v),
                            );
                          },
                          orElse: () => const SizedBox(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _qCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Question Text *'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),

                        // Options A, B, C, D
                        TextFormField(
                          controller: _optACtrl,
                          decoration: const InputDecoration(labelText: 'Option A *'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _optBCtrl,
                          decoration: const InputDecoration(labelText: 'Option B *'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _optCCtrl,
                          decoration: const InputDecoration(labelText: 'Option C *'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _optDCtrl,
                          decoration: const InputDecoration(labelText: 'Option D *'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _correctOption,
                                decoration: const InputDecoration(labelText: 'Correct Option *'),
                                items: const [
                                  DropdownMenuItem(value: 'A', child: Text('Option A')),
                                  DropdownMenuItem(value: 'B', child: Text('Option B')),
                                  DropdownMenuItem(value: 'C', child: Text('Option C')),
                                  DropdownMenuItem(value: 'D', child: Text('Option D')),
                                ],
                                onChanged: (v) => setState(() => _correctOption = v ?? 'A'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _difficulty,
                                decoration: const InputDecoration(labelText: 'Difficulty'),
                                items: const [
                                  DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                                  DropdownMenuItem(value: 'Hard', child: Text('Hard')),
                                ],
                                onChanged: (v) => setState(() => _difficulty = v ?? 'Medium'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _expCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Explanation (Optional)'),
                        ),
                        const SizedBox(height: 12),

                        // Image upload button
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isSaving ? null : _uploadImage,
                              icon: const Icon(Icons.image, size: 16),
                              label: Text(_imageUrl != null ? 'Change Image' : 'Attach Image Question'),
                            ),
                            if (_imageUrl != null) ...[
                              const SizedBox(width: 10),
                              const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Question'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
