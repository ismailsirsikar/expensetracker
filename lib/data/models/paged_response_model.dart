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
    final itemsJson = _extractItems(json);
    final meta = json['meta'] as Map<String, dynamic>?;

    return PagedResponse(
      items: itemsJson
          .map((dynamic item) => itemParser(item as Map<String, dynamic>))
          .toList(),
      page: meta?['page'] as int? ?? json['page'] as int? ?? 1,
      pageSize:
          meta?['pageSize'] as int? ??
          json['pageSize'] as int? ??
          itemsJson.length,
      totalCount:
          meta?['totalItems'] as int? ??
          meta?['totalCount'] as int? ??
          json['totalCount'] as int? ??
          itemsJson.length,
      totalPages:
          meta?['totalPages'] as int? ?? json['totalPages'] as int? ?? 1,
    );
  }

  static List<dynamic> _extractItems(Map<String, dynamic> json) {
    final candidates = <String>[
      'data',
      'items',
      'results',
      'transactions',
      'reports',
    ];

    for (final key in candidates) {
      final value = json[key];
      if (value is List<dynamic>) {
        return value;
      }
    }

    throw StateError(
      'Unable to extract paged items from response. Expected one of ${candidates.join(', ')}.',
    );
  }
}
