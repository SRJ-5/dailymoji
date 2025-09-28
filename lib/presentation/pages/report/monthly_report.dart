import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/providers/month_cluster_scores_provider.dart' show MonthParams, dailyMaxByMonthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

class MonthlyReport extends ConsumerStatefulWidget {
  const MonthlyReport({
    super.key,
    required this.userId,
  });

  final String userId; // ← 유저 ID를 외부에서 주입(로그인 유저 등)

  @override
  ConsumerState<MonthlyReport> createState() => _MonthlyReportState();
}

class _MonthlyReportState extends ConsumerState<MonthlyReport> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    // ── 여기서 key 만들고
    final key = (widget.userId, _focusedDay.year, _focusedDay.month);

    // ── 여기서 구독(ref.watch)
    final asyncRows = ref.watch(dailyMaxByMonthProvider(key));

// rows → (일 → 에셋경로) 매핑
    final emojiByDay = <int, String>{};
    asyncRows.whenData((rows) {
      for (final r in rows) {
        final d = r.createdAt.toLocal().day;
        emojiByDay[d] = clusterToAssetPath(r.cluster);
      }
    });

    // // ── 여기서 현재 달 파라미터를 만든다.
    // final params = MonthParams(
    //   userId: widget.userId,
    //   year: _focusedDay.year,
    //   month: _focusedDay.month,
    // );

    // // 뷰모델 구독: 상태(AsyncValue<ClusterMonthState>) + notifier
    // final vmState = ref.watch(clusterMonthViewModelProvider(params));
    // final vm = ref.read(clusterMonthViewModelProvider(params).notifier);

    // // 상태가 data일 때만 이모지 맵을 꺼내 쓰고, 아니면 빈 맵
    // final emojiByDay = vmState.maybeWhen(
    //   data: (s) => s.emojiByDay,
    //   orElse: () => const <int, String>{},
    // );

    return Scaffold(
      backgroundColor: AppColors.yellow50,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Column(
          children: [
            // ── 달력
            TableCalendar(
              daysOfWeekHeight: 36.h,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.sunday,

              // 페이지(월) 넘길 때 포커스 변경 → Provider family 키가 바뀌며 자동 리로드
              onPageChanged: (focused) {
                setState(() => _focusedDay = focused); // → key가 바뀌며 재요청
              },

              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },

              // 헤더 스타일
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) => "${date.year}년 ${date.month}월",
                titleTextStyle: AppFontStyles.bodyMedium14.copyWith(
                  color: AppColors.grey900,
                ),
                leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.grey900),
                rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.grey900),
              ),

              // 기본 스타일
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: true,
                todayDecoration: BoxDecoration(
                  color: AppColors.orange600,
                  shape: BoxShape.circle,
                ),
              ),

              // 날짜 커스텀 빌더
              calendarBuilders: CalendarBuilders(
                // 요일 라벨
                dowBuilder: (context, day) {
                  return Center(
                    child: Text(
                      weekdays[day.weekday % 7],
                      style: AppFontStyles.bodyMedium14.copyWith(color: AppColors.grey900),
                    ),
                  );
                },

                // 일반 날짜 셀
                defaultBuilder: (context, day, focusedDay) {
                  final path = emojiByDay[day.day]; // ← 뷰모델의 이모지 맵 사용!
                  if (path != null) {
                    return Center(child: Image.asset(path, width: 28, height: 28));
                  }
                  return SizedBox(
                    width: 40.w,
                    height: 40.h,
                    child: Center(child: Text('${day.day}')),
                  );
                },

                // 오늘 날짜 셀
                todayBuilder: (context, day, focusedDay) {
                  return Container(
                    height: 40.h,
                    width: 40.w,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.orange600,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: AppFontStyles.bodySemiBold14.copyWith(color: AppColors.grey50),
                    ),
                  );
                },

                // 선택된 날짜 셀
                selectedBuilder: (context, day, focusedDay) {
                  final path = emojiByDay[day.day];
                  return Container(
                    height: 40.h,
                    width: 40.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.orange100,
                      border: Border.all(color: AppColors.orange600, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: (path != null)
                        ? Image.asset(path)
                        : Text(
                            '${day.day}',
                            style: AppFontStyles.bodySemiBold14.copyWith(color: AppColors.orange600),
                          ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // 상태 분기(로딩/에러/데이터)
            asyncRows.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (e, _) => Text('로드 실패: $e'),
              data: (_) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 8),

            // 선택된 날짜 텍스트
            if (_selectedDay != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${_selectedDay!.month}월 ${_selectedDay!.day}일 "
                  "${weekdays[_selectedDay!.weekday % 7]}요일",
                  style: AppFontStyles.bodyBold16.copyWith(color: AppColors.grey900),
                ),
              ),

            const SizedBox(height: 12),

            // 감정 요약 카드 (현재는 더미, 나중에 선택일 기반 상세 연결)
            if (_selectedDay != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.green200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("이날 기록된 감정을 요약했어요", style: AppFontStyles.bodyBold14.copyWith(color: AppColors.green700)),
                    SizedBox(height: 6.h),
                    Text(
                      "반복되는 업무 스트레스와 주변의 기대 때문에 마음이 무거운 하루였어요. "
                      "친구와의 짧은 대화가 위로가 되었어요. 혼자만의 시간을 꼭 가지며 마음을 돌보길 해요.",
                      style: AppFontStyles.bodyRegular12_180.copyWith(color: AppColors.grey900),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: () {
                          context.push("/chat", extra: _selectedDay);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: 40.h,
                          width: 133.w,
                          padding: EdgeInsets.symmetric(vertical: 9.5.h).copyWith(left: 16.w, right: 10.w),
                          decoration: ShapeDecoration(
                            color: AppColors.green400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('채팅 확인하기', style: AppFontStyles.bodyMedium14),
                              SizedBox(width: 6.w),
                              Icon(Icons.arrow_forward, color: AppColors.grey900, size: 18.r),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String clusterToAssetPath(String cluster) {
    switch (cluster) {
      case 'neg_high':
        return AppImages.angryEmoji;
      case 'neg_low':
        return AppImages.cryingEmoji;
      case 'ADHD':
        return AppImages.shockedEmoji;
      case 'sleep':
        return AppImages.sleepingEmoji;
      case 'positive':
      default:
        return AppImages.smileEmoji;
    }
  }
}
