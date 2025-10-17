import 'package:dailymoji/data/data_sources/daily_summary_data_source.dart';
import 'package:dailymoji/data/dtos/daily_summary_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailySummaryDataSourceImpl implements DailySummaryDataSource {
  final supabase = Supabase.instance.client;

  /// 달력 한달 데이터 fetch
  @override
  Future<List<DailySummaryDto>> fetchByMonthData({
    required String userId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final res = await supabase
        .from('daily_summary')
        .select('user_id, date, top_cluster, summary_text')
        .eq('user_id', userId)
        .gte('created_at', startInclusive.toIso8601String())
        .lt('created_at', endExclusive.toIso8601String())
        .order('created_at', ascending: true);
    final test = (res as List).map((e) => DailySummaryDto.fromJson(e)).toList();
    print("22222222222222222222222222${test.first.date}");
    return test;
  }
}
