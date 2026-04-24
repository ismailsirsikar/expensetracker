class PagedResponse<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  PagedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return PagedResponse(
      items: itemsJson
          .map((dynamic item) => itemParser(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? itemsJson.length,
      totalCount: json['totalCount'] as int? ?? itemsJson.length,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}
