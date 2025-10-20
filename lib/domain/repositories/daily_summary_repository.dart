import 'package:dailymoji/domain/entities/daily_summary.dart';

abstract interface class DailySummaryRepository {
  /// 달력 한달 데이터 fetch
  Future<List<DailySummary>> fetchByMonthData({
    required String userId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  });
}
