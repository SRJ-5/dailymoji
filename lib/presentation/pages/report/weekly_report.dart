import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/data/providers/session_providers.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/icons.dart';
import 'package:dailymoji/presentation/pages/report/view_model/cluster_scores_view_model.dart';
import 'package:dailymoji/presentation/pages/report/data/gscore_service.dart'
    as gs; // ★ alias

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ===== EmotionData (UI에서 사용하는 모델) =====
class EmotionData {
  final Color color;
  final List<FlSpot> spots;
  final String description;
  final double avg;
  final double max;
  final double min;

  EmotionData({
    required this.color,
    required this.spots,
    required this.description,
    required this.avg,
    required this.max,
    required this.min,
  });
}

// ===== 체크박스: 종합 감정 점수는 제외(항상 노출) =====
final filterProvider = StateProvider<Map<String, bool>>((ref) {
  return {
    AppTextStrings.clusterNegHigh: false,
    AppTextStrings.clusterNegLow: false,
    AppTextStrings.clusterAdhd: false,
    AppTextStrings.clusterSleep: false,
    AppTextStrings.clusterPositive: false,
  };
});

class WeeklyReport extends ConsumerStatefulWidget {
  final String userId;
  const WeeklyReport({super.key, required this.userId});

  @override
  ConsumerState<WeeklyReport> createState() => _WeeklyReportState();
}

class _WeeklyReportState extends ConsumerState<WeeklyReport> {
  // FutureBuilder와 gscore_service를 사용하던 로직 제거
  // Future<gs.GScoreEmotionResult>? _gFuture; // ★ alias 타입

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(clusterScoresViewModelProvider.notifier)
          .load14DayChart(widget.userId);
    });

    // final svc = gs.GScoreService(Supabase.instance.client);
    // _gFuture = svc.fetch14DaysAsEmotionData(
    //   userId: widget.userId,
    //   color: AppColors.totalScore,
    //   description: "종합 감정 점수는 최근의 감정을 모아 보여주는 지표예요. 완벽히 좋은 점수일 필요는 없고, 그때그때의 마음을 솔직히 드러낸 기록이면 충분합니다. 수치보다 중요한 건, 당신이 꾸준히 스스로를 돌아보고 있다는 사실이에요.",
    // );
  }

  @override
  Widget build(BuildContext context) {
    // 5가지 클러스터(프론트엔드 계산)와 g-score(백엔드 계산) 데이터를 각각 watch
    final clusterState = ref.watch(clusterScoresViewModelProvider);

    // 로딩 확인
    final gScoreAsync = ref.watch(gScore14DayChartProvider(widget.userId));

    // 두 데이터 중 하나라도 로딩 중이면 로딩 인디케이터 표시
    if (clusterState.isLoading || gScoreAsync.isLoading) {
      return Container(
        height: double.infinity,
        width: double.infinity,
        color: AppColors.yellow50,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.green400,
          ),
        ),
      );
    }

    // 에러 확인
    // 두 데이터 중 하나라도 에러가 있으면 에러 메시지 표시
    if (clusterState.error != null || gScoreAsync.hasError) {
      final error = clusterState.error ?? gScoreAsync.error.toString();
      return Container(
        height: double.infinity,
        width: double.infinity,
        color: AppColors.yellow50,
        child: Center(
          child: AppText(
              '${AppTextStrings.weeklyReportError}${clusterState.error}'),
        ),
      );
    }

    // 기존 5개 감정 + 날짜
    final baseDays = clusterState.days;
    final baseMap = clusterState.emotionMap;
    final gScoreData = gScoreAsync.value;
    final weeklySummary = clusterState.weeklySummary;
    final String? overallSummaryText = weeklySummary?.overallSummary;

    // 두 종류의 데이터를 하나의 맵으로 병합
    final Map<String, EmotionData> mergedMap = {
      ...baseMap,
      if (gScoreData != null) ...{
        AppTextStrings.clusterTotalScore: EmotionData(
          color: gScoreData.color,
          spots: gScoreData.spots,
          description:
              (overallSummaryText != null && overallSummaryText.isNotEmpty)
                  ? overallSummaryText
                  : AppTextStrings.weeklyReportGScoreDescription,
          avg: gScoreData.avg,
          max: gScoreData.max,
          min: gScoreData.min,
        )
      }
    };

    // return FutureBuilder<gs.GScoreEmotionResult>(
    //   // ★ alias 타입
    //   future: _gFuture,
    //   builder: (context, snap) {
    //     // 1) 서비스 EmotionData -> UI EmotionData 로 복사해서 병합
    //     final Map<String, EmotionData> mergedMap = {
    //       ...baseMap,
    //       if (snap.hasData && snap.data?.emotion != null) ...{
    //         "종합 감정 점수": EmotionData(
    //           color: snap.data!.emotion!.color,
    //           spots: snap.data!.emotion!.spots,
    //           description: snap.data!.emotion!.description,
    //           avg: snap.data!.emotion!.avg,
    //           max: snap.data!.emotion!.max,
    //           min: snap.data!.emotion!.min,
    //         )
    //       }
    //     };

    //     // 2) 디버그(임시) — 실제로 값이 들어왔는지 바로 확인
    //     //    빌드 중 1~2회만 찍히면 정상
    //     // ignore: avoid_print
    //     print('[gscore] hasData=${snap.hasData} emotion=${snap.data?.emotion != null}');
    //     // ignore: avoid_print
    //     print('[gscore] days=${baseDays.length}');
    //     // ignore: avoid_print
    //     print('[gscore] lineYs=${mergedMap["종합 감정 점수"]?.spots.map((e) => e.y).toList()}');

    // 3) 필터(오버레이용) — 종합은 항상 별도로 그릴 거라 제외
    final filters = ref.watch(filterProvider);
    final selectedEmotions = filters.entries
        .where((e) => e.value && mergedMap.containsKey(e.key))
        .map((e) => e.key)
        .toList();

    return Container(
      color: AppColors.yellow50,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 64.h,
                  child: Center(
                    child: AppText(
                      AppTextStrings.weeklyReportTitle,
                      style: AppFontStyles.bodyMedium14.copyWith(
                        color: AppColors.grey900,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 64.h,
                    width: 64.w,
                    child: PopupMenuButton<String>(
                      color: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      icon: SvgPicture.asset(
                        AppIcons.stroke,
                        height: 18.h,
                        width: 18.w,
                      ),
                      itemBuilder: (context) {
                        return [
                          PopupMenuItem<String>(
                            child: Consumer(
                              builder: (context, ref, _) {
                                final filters = ref.watch(filterProvider);
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: filters.keys.map((key) {
                                    return InkWell(
                                      onTap: () {
                                        ref
                                            .read(filterProvider.notifier)
                                            .state = {
                                          ...filters,
                                          key: !(filters[key] ?? false),
                                        };
                                      },
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: filters[key] ?? false,
                                            activeColor: AppColors.green400,
                                            checkColor: AppColors.white,
                                            onChanged: (value) {
                                              ref
                                                  .read(filterProvider.notifier)
                                                  .state = {
                                                ...filters,
                                                key: value ?? false,
                                              };
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          AppText(
                                            key,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: filters[key] == true
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ===== 차트 =====
            Container(
              padding: EdgeInsets.all(22.r),
              child: Column(
                children: [
                  SizedBox(
                    height: 200.h,
                    child: LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(enabled: false),
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 2,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() == 0) {
                                  return const SizedBox.shrink();
                                }
                                return AppText(
                                  value.toInt().toString(),
                                  style: AppFontStyles.bodyRegular12
                                      .copyWith(color: AppColors.grey600),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 2,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= baseDays.length) {
                                  return const SizedBox.shrink();
                                }
                                // 마지막 인덱스(오늘 날짜)는 무조건 표시
                                if (index == baseDays.length - 1) {
                                  final d = baseDays[index];
                                  return AppText(
                                    "${d.month}.${d.day}",
                                    style: AppFontStyles.bodyRegular12
                                        .copyWith(color: AppColors.grey900),
                                  );
                                }
                                // 나머지는 2일 간격으로만 표시
                                if (index % 2 == 0) {
                                  final d = baseDays[index];
                                  return AppText(
                                    "${d.month}.${d.day}",
                                    style: AppFontStyles.bodyRegular12
                                        .copyWith(color: AppColors.grey600),
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (baseDays.length - 0.5).toDouble(),
                        minY: 0,
                        maxY: 10,
                        lineBarsData: [
                          // ★ 항상 그릴 “종합 감정 점수” 라인 (있을 때)
                          if (mergedMap[AppTextStrings.clusterTotalScore] !=
                              null)
                            LineChartBarData(
                              color:
                                  mergedMap[AppTextStrings.clusterTotalScore]!
                                      .color,
                              barWidth: 2,
                              dotData: FlDotData(show: false), // 보기 쉽게 점 보이기
                              spots:
                                  mergedMap[AppTextStrings.clusterTotalScore]!
                                      .spots,
                            ),

                          // 선택된 감정들 오버레이
                          ...selectedEmotions.map((key) {
                            final data = mergedMap[key]!;
                            return LineChartBarData(
                              color: data.color,
                              barWidth: 2,
                              dotData: FlDotData(show: false),
                              spots: data.spots,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ===== 범례: 줄바꿈 지원 =====
                  SizedBox(
                    width: 300.w, // 원하는 최대 폭 (없애면 가로 전체)
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8.r, // 칩 간 가로 간격
                      runSpacing: 6.r, // 줄바꿈 시 세로 간격
                      children: [
                        if (mergedMap[AppTextStrings.clusterTotalScore] != null)
                          _legendChip(
                              AppTextStrings.clusterTotalScore,
                              mergedMap[AppTextStrings.clusterTotalScore]!
                                  .color),
                        ...selectedEmotions.map(
                          (key) => _legendChip(key, mergedMap[key]!.color),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            // ===== 구분선 / 카드 (기존 그대로, 단 mergedMap 사용) =====
            Container(
              padding: EdgeInsets.only(top: 23.h),
              height: 2,
              width: double.infinity,
              color: AppColors.grey100,
            ),
            Column(
              children: [
                if (mergedMap[AppTextStrings.clusterTotalScore] != null)
                  _buildEmotionCard(AppTextStrings.clusterTotalScore,
                      mergedMap[AppTextStrings.clusterTotalScore]!),
                ...selectedEmotions
                    .map((key) => _buildEmotionCard(key, mergedMap[key]!)),
              ],
            ),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: GestureDetector(
                onTap: () {
                  context.push('/info/${AppTextStrings.srj5Test}');
                },
                child: Container(
                  height: 52.h,
                  decoration: BoxDecoration(
                      color: AppColors.green500,
                      borderRadius: BorderRadius.circular(12.r)),
                  alignment: Alignment.center,
                  child: Text(
                    AppTextStrings.checkEmotions,
                    style: AppFontStyles.bodyMedium16
                        .copyWith(color: AppColors.grey50),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ===== 카드 유틸 =====
Widget separator() {
  return Container(width: 1, height: 35, color: AppColors.grey200);
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ScoreBox(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppText(label, style: AppFontStyles.bodyBold14.copyWith(color: color)),
        SizedBox(height: 2.h),
        AppText(value,
            style:
                AppFontStyles.bodyRegular14.copyWith(color: AppColors.grey900)),
      ],
    );
  }
}

// double _avgFromSpots(List<FlSpot> spots) {
//   if (spots.isEmpty) return 0.0;
//   final ys = spots.map((s) => s.y).where((y) => y.isFinite).toList();
//   if (ys.isEmpty) return 0.0;
//   final sum = ys.fold<double>(0.0, (a, b) => a + b);
//   return double.parse((sum / ys.length).toStringAsFixed(1));
// }

// double _minFromSpots(List<FlSpot> spots) {
//   if (spots.isEmpty) return 0.0;
//   final ys = spots.map((s) => s.y).where((y) => y.isFinite).toList();
//   if (ys.isEmpty) return 0.0;
//   final m = ys.reduce((a, b) => a < b ? a : b);
//   return double.parse(m.toStringAsFixed(1));
// }

// double _maxFromSpots(List<FlSpot> spots) {
//   if (spots.isEmpty) return 0.0;
//   final ys = spots.map((s) => s.y).where((y) => y.isFinite).toList();
//   if (ys.isEmpty) return 0.0;
//   final m = ys.reduce((a, b) => a > b ? a : b);
//   return double.parse(m.toStringAsFixed(1));
// }

Widget _buildEmotionCard(String key, EmotionData data) {
  // final avg14 = _avgFromSpots(data.spots);
  // final max14 = _maxFromSpots(data.spots);
  // final min14 = _minFromSpots(data.spots);

  return Container(
    padding: EdgeInsets.only(top: 16.h),
    child: Column(
      children: [
        Row(
          spacing: 4.r,
          children: [
            Container(
              width: 8.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: data.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AppText(
              key,
              style:
                  AppFontStyles.bodyBold16.copyWith(color: AppColors.grey900),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: AppColors.green100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ScoreBox(
                      label: AppTextStrings.avgEmotionScore,
                      value: AppTextStrings.scoreUnit
                          .replaceFirst('%s', data.avg.toStringAsFixed(1)),
                      color: AppColors.green700),
                  separator(),
                  _ScoreBox(
                      label: AppTextStrings.maxEmotionScore,
                      value: AppTextStrings.scoreUnit
                          .replaceFirst('%s', data.max.toStringAsFixed(1)),
                      color: AppColors.noti100),
                  separator(),
                  _ScoreBox(
                      label: AppTextStrings.minEmotionScore,
                      value: AppTextStrings.scoreUnit
                          .replaceFirst('%s', data.min.toStringAsFixed(1)),
                      color: AppColors.noti200),
                ],
              ),
              SizedBox(height: 8.h),
              AppText(
                data.description,
                style: AppFontStyles.bodyRegular12_180
                    .copyWith(color: AppColors.grey900),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _legendChip(String label, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 4,
        decoration: ShapeDecoration(
          color: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
      ),
      const SizedBox(width: 4),
      AppText(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}
