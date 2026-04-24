import 'package:dio/dio.dart';

import '../../core/network/api_paths.dart';
import '../models/paged_response_model.dart';
import '../models/report_models.dart';

class ReportService {
  final Dio dio;

  ReportService({required this.dio});

  Future<IncomeExpenseReport> getIncomeExpenseReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await dio.get(
      ApiPaths.reportsIncomeExpense,
      queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );
    return IncomeExpenseReport.fromJson(response.data as Map<String, dynamic>);
  }

  Future<IncomeExpenseReport> getIncomeVsExpense({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return getIncomeExpenseReport(startDate: startDate, endDate: endDate);
  }

  Future<List<CategorySummaryReport>> getCategorySummaryReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await dio.get(
      ApiPaths.reportsCategorySummary,
      queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );

    final data = _normalizeListResponse(response.data, [
      'data',
      'items',
      'categorySummary',
      'categorySummaries',
      'categories',
      'results',
    ]);

    return data
        .map(
          (item) =>
              CategorySummaryReport.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<MonthlySummaryReport>> getMonthlySummaryReport({
    required int year,
  }) async {
    final response = await dio.get(
      ApiPaths.reportsMonthlySummary,
      queryParameters: {'year': year},
    );

    final data = _normalizeListResponse(response.data, [
      'data',
      'items',
      'monthlySummary',
      'monthlySummaries',
      'results',
    ]);

    return data
        .map(
          (item) => MonthlySummaryReport.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<PagedResponse<ReportItem>> getReports({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await dio.get(
      ApiPaths.reports,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );

    return PagedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ReportItem.fromJson(json),
    );
  }

  List<dynamic> _normalizeListResponse(
    Object? responseData,
    List<String> wrapperKeys,
  ) {
    if (responseData is List<dynamic>) {
      return responseData;
    }

    if (responseData is Map<String, dynamic>) {
      for (final key in wrapperKeys) {
        final wrapped = responseData[key];
        if (wrapped is List<dynamic>) {
          return wrapped;
        }
      }
    }

    throw StateError(
      'Unexpected report response type: ${responseData.runtimeType}. '
      'Expected a List or wrapper Map containing one of ${wrapperKeys.join(', ')}.',
    );
  }

  Future<List<CategorySummaryReport>> getCategorySummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return getCategorySummaryReport(startDate: startDate, endDate: endDate);
  }

  Future<List<MonthlySummaryReport>> getMonthlySummary({
    required int year,
  }) async {
    return getMonthlySummaryReport(year: year);
  }
}
