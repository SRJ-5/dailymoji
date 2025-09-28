import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/providers/month_cluster_scores_provider.dart'
    show MonthParams, dailyMaxByMonthProvider;
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
                titleTextFormatter: (date, locale) =>
                    "${date.year}년 ${date.month}월",
                titleTextStyle: AppFontStyles.bodyMedium14.copyWith(
                  color: AppColors.grey900,
                ),
                leftChevronIcon:
                    const Icon(Icons.chevron_left, color: AppColors.grey900),
                rightChevronIcon:
                    const Icon(Icons.chevron_right, color: AppColors.grey900),
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
                      style: AppFontStyles.bodyMedium14
                          .copyWith(color: AppColors.grey900),
                    ),
                  );
                },

                // 일반 날짜 셀
                defaultBuilder: (context, day, focusedDay) {
                  final path = emojiByDay[day.day]; // ← 뷰모델의 이모지 맵 사용!
                  if (path != null) {
                    return Center(
                        child: Image.asset(path, width: 28, height: 28));
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
                      style: AppFontStyles.bodySemiBold14
                          .copyWith(color: AppColors.grey50),
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
                            style: AppFontStyles.bodySemiBold14
                                .copyWith(color: AppColors.orange600),
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
                  style: AppFontStyles.bodyBold16
                      .copyWith(color: AppColors.grey900),
                ),
              ),

            const SizedBox(height: 12),

            // 감정 요약 카드 (현재는 더미, 나중에 선택일 기반 상세 연결)
            if (_selectedDay!.day == 20)
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
                    Text("이 날 불면/과수면 점수가 80점이네요.",
                        style: AppFontStyles.bodyBold14
                            .copyWith(color: AppColors.green700)),
                    SizedBox(height: 6.h),
                    Text(
                      "밤이 길게만 느껴져서 지치셨군요. 괜찮아요, 잠이 오지 않는다고 해서 당신의 하루가 가치 없는 건 아니에요. 창밖의 고요한 밤도 당신을 위로하는 한 부분일 뿐이죠. 잠들지 못하는 시간조차, 결국은 회복을 향한 과정이라는 걸 기억해 주세요.",
                      style: AppFontStyles.bodyRegular12_180
                          .copyWith(color: AppColors.grey900),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: () {
                          context.go("/report/chat", extra: _selectedDay);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: 40.h,
                          width: 133.w,
                          padding: EdgeInsets.symmetric(vertical: 9.5.h)
                              .copyWith(left: 16.w, right: 10.w),
                          decoration: ShapeDecoration(
                            color: AppColors.green400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('채팅 확인하기',
                                  style: AppFontStyles.bodyMedium14),
                              SizedBox(width: 6.w),
                              Icon(Icons.arrow_forward,
                                  color: AppColors.grey900, size: 18.r),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            if (_selectedDay!.day == 22)
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
                    Text("이 날 평온/회복 점수가 80점이네요.",
                        style: AppFontStyles.bodyBold14
                            .copyWith(color: AppColors.green700)),
                    SizedBox(height: 6.h),
                    Text(
                      "행복한 일로 가득한 하루였네요! 그 긍정의 에너지는 스스로를 지탱할 뿐 아니라 주변에도 따뜻하게 전해집니다. 오늘의 이 기분을 오래 간직하세요. 그것만으로도 이미 삶을 아름답게 물들이고 있어요.",
                      style: AppFontStyles.bodyRegular12_180
                          .copyWith(color: AppColors.grey900),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: () {
                          context.go("/report/chat", extra: _selectedDay);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: 40.h,
                          width: 133.w,
                          padding: EdgeInsets.symmetric(vertical: 9.5.h)
                              .copyWith(left: 16.w, right: 10.w),
                          decoration: ShapeDecoration(
                            color: AppColors.green400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('채팅 확인하기',
                                  style: AppFontStyles.bodyMedium14),
                              SizedBox(width: 6.w),
                              Icon(Icons.arrow_forward,
                                  color: AppColors.grey900, size: 18.r),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            if (_selectedDay!.day == 24)
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
                    Text("이 날 불안/분노 점수가 53점이네요.",
                        style: AppFontStyles.bodyBold14
                            .copyWith(color: AppColors.green700)),
                    SizedBox(height: 6.h),
                    Text(
                      "마음에 작은 불씨처럼 화가 남아 있군요. 괜찮습니다, 그 감정은 당신이 소중한 것을 지키고 싶다는 신호일지도 몰라요. 잠시 호흡을 고르며 스스로를 다독여 보세요. 화가 차분히 가라앉을 공간을 내어주는 것만으로도 충분히 잘하고 있는 거예요.",
                      style: AppFontStyles.bodyRegular12_180
                          .copyWith(color: AppColors.grey900),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: () {
                          context.go("/report/chat", extra: _selectedDay);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: 40.h,
                          width: 133.w,
                          padding: EdgeInsets.symmetric(vertical: 9.5.h)
                              .copyWith(left: 16.w, right: 10.w),
                          decoration: ShapeDecoration(
                            color: AppColors.green400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('채팅 확인하기',
                                  style: AppFontStyles.bodyMedium14),
                              SizedBox(width: 6.w),
                              Icon(Icons.arrow_forward,
                                  color: AppColors.grey900, size: 18.r),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            if (_selectedDay!.day == 26)
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
                    Text("이 날 불안/분노 점수가 72점이네요.",
                        style: AppFontStyles.bodyBold14
                            .copyWith(color: AppColors.green700)),
                    SizedBox(height: 6.h),
                    Text(
                      "마음이 쉽게 달아오르고 화가 치밀어 오를 때가 있죠. 그 감정은 억누르기보다 알아차리는 것에서부터 풀려나기 시작합니다. 깊게 숨을 내쉬고, 잠시 거리를 두어보세요. 당신의 분노는 결코 당신의 전부가 아니며, 잠시 머물다 지나가는 구름 같은 존재일 뿐이에요.",
                      style: AppFontStyles.bodyRegular12_180
                          .copyWith(color: AppColors.grey900),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: () {
                          context.go("/report/chat", extra: _selectedDay);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: 40.h,
                          width: 133.w,
                          padding: EdgeInsets.symmetric(vertical: 9.5.h)
                              .copyWith(left: 16.w, right: 10.w),
                          decoration: ShapeDecoration(
                            color: AppColors.green400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('채팅 확인하기',
                                  style: AppFontStyles.bodyMedium14),
                              SizedBox(width: 6.w),
                              Icon(Icons.arrow_forward,
                                  color: AppColors.grey900, size: 18.r),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            if (_selectedDay!.day == 28)
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
                    Text("이 날 우울/무기력/번아웃 점수가 60점이네요.",
                        style: AppFontStyles.bodyBold14
                            .copyWith(color: AppColors.green700)),
                    SizedBox(height: 6.h),
                    Text(
                      "요즘 마음이 지치고 아무 힘도 나지 않죠. 하지만 그건 당신이 약해서가 아니라, 그만큼 오래 애써왔다는 증거예요. 잠시 멈추어도 괜찮습니다. 지금은 스스로에게 회복의 시간을 선물하세요. 당신의 속도대로 다시 걸어가면 돼요.",
                      style: AppFontStyles.bodyRegular12_180
                          .copyWith(color: AppColors.grey900),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: () {
                          context.go("/report/chat", extra: _selectedDay);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          height: 40.h,
                          width: 133.w,
                          padding: EdgeInsets.symmetric(vertical: 9.5.h)
                              .copyWith(left: 16.w, right: 10.w),
                          decoration: ShapeDecoration(
                            color: AppColors.green400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('채팅 확인하기',
                                  style: AppFontStyles.bodyMedium14),
                              SizedBox(width: 6.w),
                              Icon(Icons.arrow_forward,
                                  color: AppColors.grey900, size: 18.r),
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
