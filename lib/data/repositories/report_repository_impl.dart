// DataSource를 추상화하는 Repository
import 'dart:convert';

import 'package:dailymoji/data/data_sources/report_remote_data_source.dart';
import 'package:dailymoji/domain/entities/report_record.dart';
import 'package:dailymoji/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _dataSource;

  ReportRepositoryImpl(this._dataSource);

  @override
  Future<List<ReportRecord>> getRecordsForMonth(
      String userId, DateTime month) async {
    final rawData = await _dataSource.getRecordsForMonth(userId, month);

    return rawData.map((json) {
      // score_per_cluster가 JSON 문자열로 저장되어 있을 경우 파싱
      final scoresData = json['score_per_cluster'];
      Map<String, double> scores = {};

      if (scoresData is String) {
        final decoded = jsonDecode(scoresData) as Map;
        scores = decoded.map((key, value) =>
            MapEntry(key.toString(), (value as num).toDouble()));
      } else if (scoresData is Map) {
        scores = scoresData.map((key, value) =>
            MapEntry(key.toString(), (value as num).toDouble()));
      }

      return ReportRecord(
        date: DateTime.parse(json['created_at']),
        gScore: (json['g_score'] as num).toDouble(),
        allScores: scores,
      );
    }).toList();
  }
}
