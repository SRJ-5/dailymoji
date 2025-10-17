import 'package:dailymoji/core/providers.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/data/repositories/session_repository.dart';
import 'package:dailymoji/domain/entities/weekly_summary.dart';
import 'package:dailymoji/presentation/pages/report/weekly_report.dart';
import 'package:dailymoji/presentation/providers/report_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 백엔드 RPC를 호출하는 SessionRepository를 사용하기 위한 Provider
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SessionRepository(client);
});

// 백엔드에서 14일치 g-score 통계를 가져와 차트 데이터(EmotionData)로 변환하는 Provider
final gScore14DayChartProvider =
    FutureProvider.family<EmotionData?, String>((ref, userId) async {
  final repo = ref.watch(sessionRepositoryProvider);

  // 종합감정요약 가져오기
  final summaryFuture = ref.watch(weeklySummaryProvider(userId).future);

  // 각각 await (에러는 별도 처리하고 싶으면 try/catch)
  WeeklySummary? weeklySummary;
  try {
    weeklySummary = await summaryFuture; // ✅ AsyncValue -> WeeklySummary
  } catch (_) {
    weeklySummary = null; // 주석: 실패해도 차트는 그리도록
  }
  print("아버지 날보고있다면 정답을알려줘${weeklySummary?.overallSummary}");
  print("아버지 날보고있다면 정답을알려줘${weeklySummary?.negHighSummary}");
  print("아버지 날보고있다면 정답을알려줘${weeklySummary?.negLowSummary}");
  print("아버지 날보고있다면 정답을알려줘${weeklySummary?.adhdSummary}");
  print("아버지 날보고있다면 정답을알려줘${weeklySummary?.sleepSummary}");
  print("아버지 날보고있다면 정답을알려줘${weeklySummary?.positiveSummary}");
  // 이 함수가 백엔드 RPC('get_daily_gscore_stats')를 호출합니다.
  final dailyStats = await repo.fetchDailyStatsLast14Days(userId: userId);

  if (dailyStats.isEmpty) {
    return null;
  }

  // 백엔드에서 받은 데이터를 차트 UI 모델로 변환
  final spots = <FlSpot>[];
  final validAvgs = <double>[];

  // 전체 14일 타임라인 생성
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startDate = today.subtract(const Duration(days: 13));
  final allDays = List.generate(14, (i) => startDate.add(Duration(days: i)));

  for (int i = 0; i < allDays.length; i++) {
    final day = allDays[i];
    DailyStat? statForDay;
    try {
      statForDay = dailyStats.firstWhere(
        (stat) =>
            stat.day.year == day.year &&
            stat.day.month == day.month &&
            stat.day.day == day.day,
      );
    } catch (e) {
      statForDay = null;
    }

    if (statForDay != null && statForDay.avg != null) {
      // 백엔드 g_score (0~1) -> 차트 점수 (0~100) 스케일링
      final scaledValue = (statForDay.avg! * 100).clamp(0.0, 100.0);
      spots.add(
        FlSpot(
          i.toDouble(),
          double.parse(scaledValue.toStringAsFixed(1)), // 소수점 1자리 반올림
        ),
      );
      validAvgs.add(scaledValue);
    }
  }

  if (spots.isEmpty) return null;

  final double overallAvg =
      validAvgs.reduce((a, b) => a + b) / validAvgs.length;
  final double maxAvg = validAvgs.reduce((a, b) => a > b ? a : b);
  final double minAvg = validAvgs.reduce((a, b) => a < b ? a : b);

  String pick(String fallback, String? fromApi) {
    final t = fromApi?.trim();
    return (t != null && t.isNotEmpty) ? t : fallback;
  }

  return EmotionData(
      color: AppColors.totalScore,
      spots: spots,
      avg: double.parse(overallAvg.toStringAsFixed(1)),
      max: double.parse(maxAvg.toStringAsFixed(1)),
      min: double.parse(minAvg.toStringAsFixed(1)),
      description: pick(AppTextStrings.weeklyReportGScoreDescription,
          weeklySummary?.overallSummary));
});
