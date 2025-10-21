import 'package:dailymoji/data/data_sources/daily_summary_data_source.dart';
import 'package:dailymoji/data/dtos/daily_summary_dto.dart';
import 'package:dailymoji/domain/entities/daily_summary.dart';
import 'package:dailymoji/domain/repositories/daily_summary_repository.dart';

class DailySummaryRepositoryImpl implements DailySummaryRepository {
  final DailySummaryDataSource dataSource;

  DailySummaryRepositoryImpl(this.dataSource);

  @override
  Future<List<DailySummary>> fetchByMonthData({
    required String userId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final dtos = await dataSource.fetchByMonthData(
      userId: userId,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
    return _toEntities(dtos);
  }

  // DTO → Entity 변환
  List<DailySummary> _toEntities(List<DailySummaryDto> dtos) {
    return dtos.map((d) {
      return DailySummary(
        userId: d.userId ?? '',
        date: d.date ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        summaryText: d.summaryText ?? '',
        topCluster: d.topCluster ?? '',
      );
    }).toList();
  }
}
