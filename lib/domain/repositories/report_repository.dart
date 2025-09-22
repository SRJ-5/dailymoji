import 'package:dailymoji/domain/entities/report_record.dart';

abstract class ReportRepository {
  Future<List<ReportRecord>> getRecordsForMonth(String userId, DateTime month);
}
