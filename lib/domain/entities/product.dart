class Product {
  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.priceCents,
    required this.isAvailable,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String categoryId;
  final String name;
  final int priceCents;
  final bool isAvailable;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product copyWith({
    String? categoryId,
    String? name,
    int? priceCents,
    bool? isAvailable,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      priceCents: priceCents ?? this.priceCents,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
