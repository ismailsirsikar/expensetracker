import 'package:dio/dio.dart';

import '../../core/network/api_paths.dart';
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
    final data = response.data as List<dynamic>;
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
    final data = response.data as List<dynamic>;
    return data
        .map(
          (item) => MonthlySummaryReport.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<CategorySummaryReport>> getCategorySummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return getCategorySummaryReport(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<MonthlySummaryReport>> getMonthlySummary({
    required int year,
  }) async {
    return getMonthlySummaryReport(year: year);
  }
}
