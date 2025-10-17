import 'package:dailymoji/data/dtos/daily_summary_dto.dart';

abstract interface class DailySummaryDataSource {
  /// 달력 한달 데이터 fetch
  Future<List<DailySummaryDto>> fetchByMonthData({
    required String userId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  });
}
