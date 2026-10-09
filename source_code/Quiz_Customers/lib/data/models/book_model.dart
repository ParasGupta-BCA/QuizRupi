class BookModel {
  final String id;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final double price;
  final double mrp;
  final int discountPercent;
  final String? categoryId;
  final int mcqCount;
  final String editionInfo;
  final double ratingAvg;
  final int ratingCount;
  final String stockStatus;
  final bool isBestseller;
  final bool isNew;
  final String? tag;
  final List<String> highlights;

  int get pageCount => 240;
  List<String> get bookHighlights => highlights;

  BookModel({
    required this.id,
    required this.title,
    this.description,
    this.coverImageUrl,
    required this.price,
    required this.mrp,
    this.discountPercent = 0,
    this.categoryId,
    this.mcqCount = 1000,
    this.editionInfo = '2026 Edition',
    this.ratingAvg = 4.8,
    this.ratingCount = 100,
    this.stockStatus = 'In Stock',
    this.isBestseller = false,
    this.isNew = false,
    this.tag,
    this.highlights = const [],
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    List<String> hl = [];
    if (json['book_highlights'] != null && json['book_highlights'] is List) {
      hl = (json['book_highlights'] as List)
          .map((item) => (item['highlight_text'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return BookModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 199.0,
      mrp: (json['mrp'] as num?)?.toDouble() ?? 299.0,
      discountPercent: json['discount_percent'] as int? ?? 0,
      categoryId: json['category_id'] as String?,
      mcqCount: json['mcq_count'] as int? ?? 1000,
      editionInfo: json['edition_info'] as String? ?? '2026 Edition',
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 4.8,
      ratingCount: json['rating_count'] as int? ?? 120,
      stockStatus: json['stock_status'] as String? ?? 'In Stock',
      isBestseller: json['is_bestseller'] as bool? ?? false,
      isNew: json['is_new'] as bool? ?? false,
      tag: json['tag'] as String?,
      highlights: hl,
    );
  }
}
