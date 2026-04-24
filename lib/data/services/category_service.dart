import 'package:dio/dio.dart';

import '../../core/network/api_paths.dart';
import '../models/category_model.dart';

class CategoryService {
  final Dio dio;

  CategoryService({required this.dio});

  Future<List<CategoryModel>> getCategories() async {
    final response = await dio.get(ApiPaths.categories);
    final data = response.data as List<dynamic>;
    return data
        .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryModel> createCategory(
    String categoryName, {
    bool isMainCategory = false,
  }) async {
    final response = await dio.post(
      ApiPaths.categories,
      data: {
        'categoryName': categoryName,
        'isMainCategory': isMainCategory,
      },
    );
    return CategoryModel.fromJson(response.data as Map<String, dynamic>);
  }
}
