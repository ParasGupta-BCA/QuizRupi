import 'package:cached_network_image/cached_network_image.dart';
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
import '../../providers/books_admin_provider.dart';
import '../../providers/quiz_admin_provider.dart';

class BooksManagementScreen extends ConsumerWidget {
  const BooksManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final booksAsync = ref.watch(booksAdminListProvider);
    final categoriesAsync = ref.watch(quizCategoriesProvider);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Books & Store Inventory',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                      Text(
                        'Manage book titles, pricing, highlights, active status, and cover photos',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openBookEditor(context, ref, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New Book'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search & Category Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search books by title...',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (val) {
                      ref.read(bookSearchProvider.notifier).state = val;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                categoriesAsync.maybeWhen(
                  data: (cats) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: ref.watch(bookCategoryFilterProvider),
                        hint: const Text('All Categories', style: TextStyle(fontSize: 13)),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...cats.map((c) => DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text(c.name),
                              )),
                        ],
                        onChanged: (val) {
                          ref.read(bookCategoryFilterProvider.notifier).state = val;
                        },
                      ),
                    ),
                  ),
                  orElse: () => const SizedBox(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Books List
            Expanded(
              child: booksAsync.when(
                loading: () => const SkeletonListLoader(count: 6),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Failed to load books: $err'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(booksAdminListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (books) {
                  if (books.isEmpty) {
                    return EmptyState(
                      icon: Icons.menu_book,
                      title: 'No Books Found',
                      message: 'No books match the selected filters. Add your first book above!',
                      actionLabel: 'Add Book',
                      onAction: () => _openBookEditor(context, ref, null),
                    );
                  }

                  return Card(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: books.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final book = books[idx];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 48,
                              height: 64,
                              color: Colors.grey.shade200,
                              child: book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: book.coverImageUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => const Icon(Icons.menu_book, color: Colors.grey),
                                    )
                                  : const Icon(Icons.menu_book, color: Colors.grey),
                            ),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (book.isBestseller)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Bestseller',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondaryDark),
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: book.isActive
                                          ? AppColors.success.withValues(alpha: 0.15)
                                          : Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      book.isActive ? 'Active' : 'Hidden',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: book.isActive ? AppColors.success : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    currency.format(book.price),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  Text(
                                    currency.format(book.mrp),
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${book.discountPercent}% OFF',
                                    style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  Text('• ${book.mcqCount} MCQs', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  Text('• ${book.stockStatus}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              if (book.highlights.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Highlights: ${book.highlights.join(" • ")}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                tooltip: book.isActive ? 'Hide Book' : 'Activate Book',
                                icon: Icon(
                                  book.isActive ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: book.isActive ? AppColors.primary : Colors.grey,
                                  size: 18,
                                ),
                                onPressed: () async {
                                  await ref.read(adminServiceProvider).toggleBookActive(book.id, !book.isActive);
                                  ref.invalidate(booksAdminListProvider);
                                },
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => _openBookEditor(context, ref, book),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () => _confirmDelete(context, ref, book),
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

  void _openBookEditor(BuildContext context, WidgetRef ref, BookModel? existingBook) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BookEditorDialog(book: existingBook),
    ).then((_) {
      ref.invalidate(booksAdminListProvider);
    });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, BookModel book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Book?'),
        content: Text('Are you sure you want to delete "${book.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminServiceProvider).deleteBook(book.id);
              ref.invalidate(booksAdminListProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _BookEditorDialog extends ConsumerStatefulWidget {
  final BookModel? book;

  const _BookEditorDialog({this.book});

  @override
  ConsumerState<_BookEditorDialog> createState() => _BookEditorDialogState();
}

class _BookEditorDialogState extends ConsumerState<_BookEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _mrpCtrl;
  late final TextEditingController _mcqCtrl;
  late final TextEditingController _editionCtrl;
  late final TextEditingController _tagCtrl;
  late final TextEditingController _highlightsCtrl;
  String? _coverImageUrl;
  String? _categoryId;
  String _stockStatus = 'In Stock';
  bool _isBestseller = false;
  bool _isNew = false;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _descCtrl = TextEditingController(text: b?.description ?? '');
    _priceCtrl = TextEditingController(text: b?.price.toString() ?? '299');
    _mrpCtrl = TextEditingController(text: b?.mrp.toString() ?? '599');
    _mcqCtrl = TextEditingController(text: b?.mcqCount.toString() ?? '1000');
    _editionCtrl = TextEditingController(text: b?.editionInfo ?? '2026 Edition');
    _tagCtrl = TextEditingController(text: b?.tag ?? '');
    _highlightsCtrl = TextEditingController(text: b?.highlights.join('\n') ?? '');
    _coverImageUrl = b?.coverImageUrl;
    _categoryId = b?.categoryId;
    _stockStatus = b?.stockStatus ?? 'In Stock';
    _isBestseller = b?.isBestseller ?? false;
    _isNew = b?.isNew ?? false;
    _isActive = b?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _mrpCtrl.dispose();
    _mcqCtrl.dispose();
    _editionCtrl.dispose();
    _tagCtrl.dispose();
    _highlightsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadCover() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
    );

    if (result.isNotEmpty) {
      final file = result.first;
      setState(() => _isSaving = true);
      try {
        final bytes = await file.readAsBytes();
        final url = await ref.read(adminServiceProvider).uploadImage(
              bytes,
              file.name,
              SupabaseConstants.bucketBookCovers,
            );
        setState(() {
          _coverImageUrl = url;
          _isSaving = false;
        });
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    final mrp = double.tryParse(_mrpCtrl.text) ?? price;
    final discount = mrp > 0 ? (((mrp - price) / mrp) * 100).round() : 0;
    final mcq = int.tryParse(_mcqCtrl.text) ?? 1000;
    final highlights = _highlightsCtrl.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    setState(() => _isSaving = true);

    final service = ref.read(adminServiceProvider);
    try {
      if (widget.book == null) {
        final newBook = BookModel(
          id: '',
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          coverImageUrl: _coverImageUrl,
          price: price,
          mrp: mrp,
          discountPercent: discount,
          categoryId: _categoryId,
          mcqCount: mcq,
          editionInfo: _editionCtrl.text.trim(),
          stockStatus: _stockStatus,
          isBestseller: _isBestseller,
          isNew: _isNew,
          tag: _tagCtrl.text.trim().isNotEmpty ? _tagCtrl.text.trim() : null,
          isActive: _isActive,
          createdAt: DateTime.now(),
        );
        await service.createBook(newBook, highlights);
      } else {
        final updatedBook = widget.book!.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          coverImageUrl: _coverImageUrl,
          price: price,
          mrp: mrp,
          discountPercent: discount,
          categoryId: _categoryId,
          mcqCount: mcq,
          editionInfo: _editionCtrl.text.trim(),
          stockStatus: _stockStatus,
          isBestseller: _isBestseller,
          isNew: _isNew,
          tag: _tagCtrl.text.trim().isNotEmpty ? _tagCtrl.text.trim() : null,
          isActive: _isActive,
        );
        await service.updateBook(updatedBook, highlights);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving book: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(quizCategoriesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 750),
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
                      widget.book == null ? 'Add New Book' : 'Edit Book',
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
                        // Cover photo upload
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 105,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: _coverImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: _coverImageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.menu_book, size: 36, color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _isSaving ? null : _pickAndUploadCover,
                                  icon: const Icon(Icons.upload, size: 16),
                                  label: const Text('Upload Cover Image'),
                                ),
                                const SizedBox(height: 4),
                                const Text('Formats: JPG, PNG, WEBP. Uploads to Supabase storage.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Title
                        const Text('Title *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(hintText: 'e.g. UPSC General Studies Complete Guide'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Pricing Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sale Price (₹) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _priceCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(hintText: '299'),
                                    validator: (v) => v == null || double.tryParse(v) == null ? 'Enter price' : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('MRP (₹) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _mrpCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(hintText: '599'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('MCQs Count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _mcqCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(hintText: '1000'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Category & Stock Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  categoriesAsync.maybeWhen(
                                    data: (cats) => DropdownButtonFormField<String?>(
                                      value: _categoryId,
                                      decoration: const InputDecoration(),
                                      items: [
                                        const DropdownMenuItem<String?>(value: null, child: Text('None')),
                                        ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                                      ],
                                      onChanged: (v) => setState(() => _categoryId = v),
                                    ),
                                    orElse: () => const SizedBox(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Stock Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _stockStatus,
                                    decoration: const InputDecoration(),
                                    items: const [
                                      DropdownMenuItem(value: 'In Stock', child: Text('In Stock')),
                                      DropdownMenuItem(value: 'Low Stock', child: Text('Low Stock')),
                                      DropdownMenuItem(value: 'Out of Stock', child: Text('Out of Stock')),
                                    ],
                                    onChanged: (v) => setState(() => _stockStatus = v ?? 'In Stock'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Edition & Tag Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Edition', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _editionCtrl,
                                    decoration: const InputDecoration(hintText: '2026 Edition'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Badge / Tag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _tagCtrl,
                                    decoration: const InputDecoration(hintText: 'e.g. Top Rated'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Description
                        const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(hintText: 'Full book description...'),
                        ),
                        const SizedBox(height: 16),

                        // Key Highlights
                        const Text('Key Highlights (One bullet per line)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _highlightsCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(hintText: '1000+ Practice MCQs\nDetailed Explanations\nPast 10 Years Solved Papers'),
                        ),
                        const SizedBox(height: 16),

                        // Flags
                        Row(
                          children: [
                            Checkbox(
                              value: _isBestseller,
                              onChanged: (v) => setState(() => _isBestseller = v ?? false),
                            ),
                            const Text('Bestseller'),
                            const SizedBox(width: 20),
                            Checkbox(
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v ?? true),
                            ),
                            const Text('Active (Visible in Store)'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Book'),
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
