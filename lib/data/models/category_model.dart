class CategoryModel {
  final String? id;
  final String categoryName;
  final bool isMainCategory;

  CategoryModel({
    this.id,
    required this.categoryName,
    required this.isMainCategory,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String?,
      categoryName:
          json['categoryName'] as String? ?? json['name'] as String? ?? '',
      isMainCategory: json['isMainCategory'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'categoryName': categoryName,
      'isMainCategory': isMainCategory,
    };
  }
}
