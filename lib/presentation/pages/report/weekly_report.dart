import 'dart:math';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
//추가로 해야할 일
//각 spot은 null일 수 있어야함.
//그에 따라 그래프는 12일에 1, 14일에 10이 들어있고 중간값인 13일에 null이라면, 1부터 10까지가 이어지도록 그려야함

// 차트가 왼쪽에서부터 생성되는 로직 구현 해야함

// 최근 14일 날짜 리스트 생성 함수
List<DateTime> generateLast14Days() {
  final today = DateTime.now();
  return List.generate(
    15,
    (index) => today.subtract(Duration(days: 14 - index)), // 오래된 → 최신 순
  );
}

// 날짜 리스트 생성
final last14Days = generateLast14Days();

// 감정 데이터 (랜덤으로 spots 생성) // 나중에 실제 데이터가 연동되면 삭제할 함수
List<FlSpot> generateRandomSpots(List<DateTime> days) {
  final random = Random();
  return List.generate(
    days.length,
    (i) => FlSpot(i.toDouble(), random.nextInt(10).toDouble()), // 0~9 사이 랜덤
  );
}

// 감정 데이터 맵
final emotionMap = {
  "종합 감정 점수": EmotionData(
    color: AppColors.totalScore,
    spots: generateRandomSpots(last14Days),
    avg: 6, // flspot의 모든 y값을 더해서 last14Days.length로 나눈 숫자
    max: 8, // flspot의 모든 y값을 탐색후 가장 높은 숫자
    min: 3, // flspot의 모든 y값을 탐색후 가장 낮은 숫자
    description: "종합적인 감정 흐름을 보여줍니다.",
  ),
  "불안/분노": EmotionData(
    color: AppColors.negHigh,
    spots: generateRandomSpots(last14Days),
    avg: 6,
    max: 8,
    min: 3,
    description:
        "스트레스 지수가 연속 3일간 상승했어요. 잠시라도 깊게 숨을 들이쉬고 내쉬는 것만으로도 마음이 한결 가벼워질 수 있어요. 자신에게 짧은 휴식을 선물해보세요.",
  ),
  "우울/무기력/번아웃": EmotionData(
    color: AppColors.negLow,
    spots: generateRandomSpots(last14Days),
    avg: 6,
    max: 8,
    min: 3,
    description: "지쳤다는 신호가 보여요. 잠시 쉬어가세요.",
  ),
  "평온/회복": EmotionData(
    color: AppColors.positive,
    spots: generateRandomSpots(last14Days),
    avg: 7,
    max: 9,
    min: 5,
    description: "안정적인 감정 상태가 유지되고 있어요.",
  ),
  "불면/과다수면": EmotionData(
    color: AppColors.sleep,
    spots: generateRandomSpots(last14Days),
    avg: 7,
    max: 9,
    min: 5,
    description: "안정적인 감정 상태가 유지되고 있어요.",
  ),
  "ADHD": EmotionData(
    color: AppColors.adhd,
    spots: generateRandomSpots(last14Days),
    avg: 7,
    max: 9,
    min: 5,
    description: "안정적인 감정 상태가 유지되고 있어요.",
  ),
};

// 감정 데이터 모델
class EmotionData {
  final Color color;
  final List<FlSpot> spots;
  final String description;
  final int avg;
  final int max;
  final int min;

  EmotionData({
    required this.color,
    required this.spots,
    required this.description,
    required this.avg,
    required this.max,
    required this.min,
  });
}

// 필터 Provider (종합 감정 점수 제외 → 체크리스트는 5개만)
final filterProvider = StateProvider<Map<String, bool>>((ref) {
  return {
    "불안/분노": false,
    "우울/무기력/번아웃": false,
    "ADHD": false,
    "불면/과다수면": false,
    "평온/회복": false,
  };
});

class WeeklyReport extends ConsumerWidget {
  const WeeklyReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filterProvider);

    // 현재 선택된 감정 리스트
    final selectedEmotions = filters.entries
        .where((entry) => entry.value && emotionMap.containsKey(entry.key))
        .map((entry) => entry.key)
        .toList();

    return Container(
      color: AppColors.yellow50,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 타이틀 + 필터 아이콘
            Stack(
              children: [
                SizedBox(
                  height: 64.h,
                  child: Center(
                    child: Text(
                      "나의 2주간 감정 상태",
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
                          // 직접 만든 체크박스
                          PopupMenuItem<String>(
                            child: Consumer(
                              builder: (context, ref, _) {
                                final filters = ref.watch(filterProvider);
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: filters.keys.map((key) {
                                    return InkWell(
                                      onTap: () {
                                        // 체크박스와 텍스트 클릭 시 상태 토글
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
                                            activeColor:
                                                AppColors.green400, // 체크 시 색상
                                            checkColor:
                                                AppColors.white, // 체크 표시 색상
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
                                          Text(
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

            // 라인 차트 박스
            Container(
              padding: EdgeInsets.all(22.r),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        // 터치 이벤트 끄기
                        lineTouchData: LineTouchData(
                          enabled: false,
                        ),

                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 2, // y축 간격 (예: 2단위)
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() == 0) {
                                  return const SizedBox.shrink(); // ✅ 0은 표시 안 함
                                }
                                return Text(
                                  value.toInt().toString(),
                                  style: AppFontStyles.bodyRegular12
                                      .copyWith(color: AppColors.grey600),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 2,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= last14Days.length) {
                                  return const SizedBox.shrink();
                                }
                                final date = last14Days[index];
                                return Text(
                                  "${date.month}.${date.day}",
                                  style: AppFontStyles.bodyRegular12
                                      .copyWith(color: AppColors.grey600),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        minX: 0,
                        maxX: (last14Days.length - 1).toDouble(),
                        minY: 0,
                        maxY: 10,
                        lineBarsData: [
                          // ✅ 종합 감정 점수는 항상 추가
                          LineChartBarData(
                            color: emotionMap["종합 감정 점수"]!.color,
                            barWidth: 2,
                            dotData: FlDotData(show: false),
                            spots: emotionMap["종합 감정 점수"]!.spots,
                          ),

                          // ✅ 선택된 감정 라인들 추가
                          ...selectedEmotions.map((key) {
                            final data = emotionMap[key]!;
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

                  // 범례
                  SizedBox(
                    width: 300.w,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8.r,
                      children: selectedEmotions
                          .map((key) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 4,
                                    decoration: ShapeDecoration(
                                      color: emotionMap[key]!.color,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(2)),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(key,
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            // 경계선
            Container(
              padding: EdgeInsets.only(top: 23.h),
              height: 2,
              width: double.infinity,
              color: AppColors.grey100,
            ),
            // 기록 감정 부분
            Column(
              children: [
                // ✅ 종합 감정 점수는 항상 표시
                _buildEmotionCard("종합 감정 점수", emotionMap["종합 감정 점수"]!),

                // ✅ 선택된 감정이 있으면 그 카드들도 추가
                ...selectedEmotions.map((key) {
                  final data = emotionMap[key]!;
                  return _buildEmotionCard(key, data);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 감정 상태 카드의 분리선
Widget separator() {
  return Container(
      width: 1,
      height: 35, // 선 높이
      color: AppColors.grey200);
}

// 점수 박스 위젯
class _ScoreBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppFontStyles.bodyBold14.copyWith(color: color)),
        SizedBox(height: 2.h),
        Text(value,
            style:
                AppFontStyles.bodyRegular14.copyWith(color: AppColors.grey900)),
      ],
    );
  }
}

// 감정 점수 카드 만드는 함수
Widget _buildEmotionCard(String key, EmotionData data) {
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
            Text(
              key,
              style: AppFontStyles.bodyBold16.copyWith(
                color: AppColors.grey900,
              ),
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
                      label: "평균 감정 점수",
                      value: "${data.avg}점",
                      color: AppColors.green700),
                  separator(),
                  _ScoreBox(
                      label: "최고 감정 점수",
                      value: "${data.max}점",
                      color: AppColors.noti100),
                  separator(),
                  _ScoreBox(
                      label: "최저 감정 점수",
                      value: "${data.min}점",
                      color: AppColors.noti200),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
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
