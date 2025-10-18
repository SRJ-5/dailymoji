import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/domain/entities/daily_summary.dart';
import 'package:dailymoji/presentation/pages/report/view_model/daily_summary_view_model.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

/// 날짜(년월일)만 비교/키로 쓰기
bool isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class MonthlyReport extends ConsumerStatefulWidget {
  const MonthlyReport({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  ConsumerState<MonthlyReport> createState() => _MonthlyReportState();
}

class _MonthlyReportState extends ConsumerState<MonthlyReport> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  bool _isSummaryLoading = false; // (필요 시 API로 하루요약 따로 뽑을 때 사용)

  /// 탑클러스터 -> 이모지
  String clusterToAssetPath(String cluster) {
    switch (cluster) {
      case "neg_high": // ← 오타 주의: 예전 코드에 "neg_hige" 였음
        return AppImages.angryEmoji;
      case "neg_low":
        return AppImages.cryingEmoji;
      case "adhd":
        return AppImages.shockedEmoji;
      case "sleep":
        return AppImages.sleepingEmoji;
      case "positive":
      default:
        return AppImages.smileEmoji;
    }
  }

  /// 탑클러스터 -> 앱텍스트
  String clusterToAssetText(String cluster) {
    switch (cluster) {
      case "neg_high":
        return AppTextStrings.clusterNegHigh;
      case "neg_low":
        return AppTextStrings.clusterNegLow;
      case "adhd":
        return AppTextStrings.clusterAdhd;
      case "sleep":
        return AppTextStrings.clusterSleep;
      case "positive":
      default:
        return AppTextStrings.clusterPositive;
    }
  }

  @override
  void initState() {
    super.initState();

    // 첫 진입 시 현재 월 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(dailySummaryViewModelProvider.notifier)
          .fetchMonthData(widget.userId, _focusedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monthState = ref.watch(dailySummaryViewModelProvider);
    final monthVm = ref.read(dailySummaryViewModelProvider.notifier);

    // 월 리스트 -> 맵<날짜, 데이터> (키는 dateOnly : 시, 분, 초 짜름)
    final Map<DateTime, DailySummary> summaryByDate = {
      for (final s in monthState.dailySummaries) DateUtils.dateOnly(s.date): s,
    };

    // 선택 키 & 선택일 데이터
    final DateTime selectedKey =
        DateUtils.dateOnly(_selectedDay ?? _focusedDay);
    final DailySummary? selectedSummary = summaryByDate[selectedKey];
    final bool hasRecordOnSelectedDay = selectedSummary != null;

    // 요약 카드 타이틀
    final summaryTitle = hasRecordOnSelectedDay
        ? AppTextStrings.getMonthlyReportSummaryTitle(
            clusterName: clusterToAssetText(selectedSummary.topCluster),
          )
        : AppTextStrings.monthlyReportNoRecord;

    return Scaffold(
      backgroundColor: AppColors.yellow50,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w).copyWith(bottom: 8.h),
        child: SingleChildScrollView(
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
                onPageChanged: (focused) {
                  setState(() => _focusedDay = focused);
                  monthVm.fetchMonthData(widget.userId, focused);

                  // (월 선택) 선택일이 다른 달로 넘어갔으면 포커스로 보정
                  if (_selectedDay != null &&
                      _selectedDay!.month != focused.month) {
                    setState(() => _selectedDay = focused);
                  }
                },
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextFormatter: (date, locale) => DateFormat(
                          AppTextStrings.monthlyReportDateFormat, 'ko_KR')
                      .format(date),
                  titleTextStyle: AppFontStyles.bodyMedium14
                      .copyWith(color: AppColors.grey900),
                  leftChevronIcon:
                      const Icon(Icons.chevron_left, color: AppColors.grey900),
                  rightChevronIcon:
                      const Icon(Icons.chevron_right, color: AppColors.grey900),
                ),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  // todayDecoration은 todayBuilder를 쓰면 무시됨
                ),
                calendarBuilders: CalendarBuilders(
                  // 요일 라벨
                  dowBuilder: (context, day) => Center(
                    child: AppText(
                      DateFormat('E', 'ko_KR').format(day),
                      style: AppFontStyles.bodyMedium14
                          .copyWith(color: AppColors.grey900),
                    ),
                  ),

                  // 일반 날짜 셀
                  defaultBuilder: (context, day, focusedDay) {
                    final data = summaryByDate[DateUtils.dateOnly(day)];
                    if (data != null && data.topCluster.isNotEmpty) {
                      final path = clusterToAssetPath(data.topCluster);
                      return SizedBox(
                        width: 40.w,
                        height: 40.h,
                        child: Center(
                          child: Image.asset(path, width: 36.w, height: 36.h),
                        ),
                      );
                    }
                    return SizedBox(
                      width: 40.w,
                      height: 40.h,
                      child: Center(
                        child: AppText(
                          '${day.day}',
                          style: AppFontStyles.bodyMedium14
                              .copyWith(color: AppColors.grey900),
                        ),
                      ),
                    );
                  },

                  // 오늘 날짜 셀
                  todayBuilder: (context, day, focusedDay) => Container(
                    height: 40.h,
                    width: 40.w,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.orange600,
                      shape: BoxShape.circle,
                    ),
                    child: AppText(
                      '${day.day}',
                      style: AppFontStyles.bodySemiBold14
                          .copyWith(color: AppColors.grey50),
                    ),
                  ),

                  // 선택된 날짜 셀
                  selectedBuilder: (context, day, focusedDay) {
                    final data = summaryByDate[DateUtils.dateOnly(day)];
                    if (data != null && data.topCluster.isNotEmpty) {
                      final path = clusterToAssetPath(data.topCluster);
                      return Container(
                        alignment: Alignment.center,
                        height: 40.h,
                        width: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.orange600, width: 2.sp),
                        ),
                        child: Center(child: Image.asset(path)),
                      );
                    }
                    return Container(
                      height: 40.h,
                      width: 40.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.orange100,
                        border:
                            Border.all(color: AppColors.orange600, width: 1),
                      ),
                      child: Center(
                        child: AppText(
                          '${day.day}',
                          style: AppFontStyles.bodySemiBold14
                              .copyWith(color: AppColors.orange600),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 16.h),
              Divider(height: 1.h, color: AppColors.grey100),
              SizedBox(height: 16.h),

              // 선택된 날짜 텍스트
              if (_selectedDay != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppText(
                    DateFormat(AppTextStrings.monthlyReportDayFormat, 'ko_KR')
                        .format(_selectedDay!),
                    style: AppFontStyles.bodyBold16
                        .copyWith(color: AppColors.grey900),
                  ),
                ),

              SizedBox(height: 8.h),

              // ── 요약 카드: 데이터 있으면 카드, 없으면 "기록 없음"
              if (hasRecordOnSelectedDay)
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
                      AppText(
                        summaryTitle,
                        style: AppFontStyles.bodyBold14
                            .copyWith(color: AppColors.green700),
                      ),
                      SizedBox(height: 6.h),
                      if (_isSummaryLoading)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            child: const CircularProgressIndicator(),
                          ),
                        )
                      else
                        AppText(
                          selectedSummary.summaryText,
                          style: AppFontStyles.bodyRegular12_180
                              .copyWith(color: AppColors.grey900),
                        ),
                      SizedBox(height: 16.h),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(133, 40),
                            backgroundColor: AppColors.grey50,
                            side: const BorderSide(color: AppColors.grey200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 9.5.h)
                                .copyWith(left: 16.w, right: 10.w),
                          ),
                          onPressed: () {
                            context.go("/report/chat", extra: _selectedDay);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppTextStrings.checkChatHistory,
                                style: AppFontStyles.bodyMedium14
                                    .copyWith(color: AppColors.grey900),
                              ),
                              SizedBox(width: 6.w),
                              Icon(Icons.arrow_forward,
                                  color: AppColors.grey900, size: 18.r),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.only(top: 70.h),
                  child: AppText(
                    AppTextStrings.monthlyReportNoRecord, // "이 날은 기록이 없는 하루예요"
                    style: AppFontStyles.bodyRegular12_180
                        .copyWith(color: AppColors.grey700),
                  ),
                ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
