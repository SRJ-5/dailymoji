import 'dart:convert';
import 'package:dailymoji/core/config/api_config.dart';
import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/domain/enums/cluster_type.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/domain/entities/cluster_score.dart';
import 'package:dailymoji/presentation/pages/report/data/month_cluster_mapping.dart';
import 'package:dailymoji/presentation/providers/month_cluster_scores_provider.dart'
    show MonthParams, dailyMaxByMonthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// RIN: 날짜(년,월,일)만 비교하기 위한 유틸리티 함수
bool isSameDate(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

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

  // bool checkEmoji = false;

  String _dailySummary = AppTextStrings.monthlyReportDefaultSummary;
  bool _isSummaryLoading = false;

  /// 점수를 100배 후 정수 반환 (반올림)
  int displayScore100(double score) => (score * 100).round();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    // 앱 시작 시 오늘 날짜의 '기본 안내 문구'를 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchDailySummary(DateTime.now());
      }
    });
  }

// RIN: _fetchDailySummary 갈아엎음
  Future<void> _fetchDailySummary(DateTime selectedDay) async {
    // provider로부터 해당 월의 데이터를 읽어옴
    final asyncRows = ref.read(dailyMaxByMonthProvider(
        (widget.userId, selectedDay.year, selectedDay.month)));
    final rows = asyncRows.asData?.value ?? [];
    final bool hasRecord =
        rows.any((r) => isSameDate(r.createdAt.toLocal(), selectedDay));

    final now = DateTime.now();
    final bool isPastDate =
        !isSameDate(selectedDay, now) && selectedDay.isBefore(now);

    // 1. 기록이 없는 '과거' 날짜인 경우
    if (!hasRecord && isPastDate) {
      setState(() {
        _isSummaryLoading = false;
        _dailySummary = AppTextStrings.monthlyReportNoRecord;
      });
      return;
    }

    // 2. 그 외의 경우 (기록이 있거나, 오늘 날짜이거나, 미래 날짜) API 호출
    if (widget.userId.isEmpty) return;

    setState(() {
      _isSummaryLoading = true;
      _dailySummary = AppTextStrings.monthlyReportLoadingSummary;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/report/summary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'date': DateFormat('yyyy-MM-dd').format(selectedDay),
        }),
      );

      if (mounted && response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _dailySummary = data['summary'];
        });
      } else if (mounted) {
        setState(() {
          _dailySummary = AppTextStrings.monthlyReportFailedSummary;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dailySummary =
              "${AppTextStrings.monthlyReportErrorSummary.split('%s')[0]}$e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSummaryLoading = false;
        });
      }
    }
  }

  String clusterToAssetPath(String cluster) {
    // RIN: Enum사용하여 매핑
    switch (ClusterType.fromString(cluster)) {
      case ClusterType.negHigh:
        return AppImages.angryEmoji;
      case ClusterType.negLow:
        return AppImages.cryingEmoji;
      case ClusterType.adhd:
        return AppImages.shockedEmoji;
      case ClusterType.sleep:
        return AppImages.sleepingEmoji;
      case ClusterType.positive:
      default:
        return AppImages.smileEmoji;
    }
  }

  @override
  Widget build(BuildContext context) {
    // final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    // ── 여기서 key 만들고
    final key = (widget.userId, _focusedDay.year, _focusedDay.month);

    // ── 여기서 구독(ref.watch)
    final asyncRows = ref.watch(dailyMaxByMonthProvider(key));

    // rows → (일 → 에셋경로) 매핑
    final rows = asyncRows.asData?.value; // List<ClusterScore>? (data 상태일 때만 값)
    final emojiByDay = <int, String>{};
    if (rows != null) {
      for (final r in rows) {
        final d = r.createdAt.toLocal().day;
        emojiByDay[d] = clusterToAssetPath(r.cluster);
      }
    }

    // 선택된 날짜의 ClusterScore 찾기
    ClusterScore? selectedRow;
    if (rows != null && _selectedDay != null) {
      final sd = _selectedDay!;
      // firstWhere는 요소를 찾지 못하면 에러를 발생시키므로, try-catch 대신 안전한 방식으로 변경
      selectedRow = rows.cast<ClusterScore?>().firstWhere(
            (r) => r != null && isSameDate(r.createdAt.toLocal(), sd),
            orElse: () => null,
          );
    }

    final bool hasRecordOnSelectedDay = selectedRow != null;

    // 요약 카드 제목 문구
    final summaryTitle = (selectedRow == null)
        ? AppTextStrings.monthlyReportNoRecord
        : AppTextStrings.getMonthlyReportSummaryTitle(
            clusterName: ClusterUtil.getDisplayName(selectedRow.cluster),
          );

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

                // 페이지(월) 넘길 때 포커스 변경 → Provider family 키가 바뀌며 자동 리로드
                onPageChanged: (focused) {
                  setState(() => _focusedDay = focused); // → key가 바뀌며 재요청
                },

                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                  _fetchDailySummary(selected);
                },

                // 헤더 스타일
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextFormatter: (date, locale) => DateFormat(
                          AppTextStrings.monthlyReportDateFormat, 'ko_KR')
                      .format(date),
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
                  outsideDaysVisible: false,
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
                      child: AppText(
                        DateFormat('E', 'ko_KR').format(day),
                        style: AppFontStyles.bodyMedium14
                            .copyWith(color: AppColors.grey900),
                      ),
                    );
                  },

                  // 일반 날짜 셀
                  defaultBuilder: (context, day, focusedDay) {
                    final path = emojiByDay[day.day]; // ← 뷰모델의 이모지 맵 사용!
                    if (path != null) {
                      return SizedBox(
                        width: 40.w,
                        height: 40.h,
                        child: Center(
                            child:
                                Image.asset(path, width: 36.w, height: 36.h)),
                      );
                    }
                    return SizedBox(
                      width: 40.w,
                      height: 40.h,
                      child: Center(child: AppText('${day.day}')),
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
                      child: AppText(
                        '${day.day}',
                        style: AppFontStyles.bodySemiBold14
                            .copyWith(color: AppColors.grey50),
                      ),
                    );
                  },

                  // 선택된 날짜 셀
                  selectedBuilder: (context, day, focusedDay) {
                    final path = emojiByDay[day.day];
                    // checkEmoji = path == null ? false : true;
                    return path == null
                        ? Container(
                            height: 40.h,
                            width: 40.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.orange100,
                              border: Border.all(
                                  color: AppColors.orange600, width: 1),
                            ),
                            child: Center(
                              child: AppText(
                                '${day.day}',
                                style: AppFontStyles.bodySemiBold14
                                    .copyWith(color: AppColors.orange600),
                              ),
                            ),
                          )
                        : Container(
                            alignment: Alignment.center,
                            height: 40.h,
                            width: 40.w,
                            decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.orange600,
                                  width: 2.sp,
                                )),
                            child: Center(child: Image.asset(path)));
                  },
                ),
              ),
              SizedBox(height: 16.h),
              Divider(
                height: 1.h,
                color: AppColors.grey100,
              ),
              SizedBox(height: 16.h),

              // 상태 분기(로딩/에러/데이터)
              asyncRows.when(
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (e, _) => AppText('로드 실패: $e'),
                data: (_) => const SizedBox.shrink(),
              ),

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

              // 감정 요약 카드 (현재는 더미, 나중에 선택일 기반 상세 연결)
              if (_selectedDay != null)
                hasRecordOnSelectedDay
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.green100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.green200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(summaryTitle,
                                style: AppFontStyles.bodyBold14
                                    .copyWith(color: AppColors.green700)),
                            SizedBox(height: 6.h),
                            if (_isSummaryLoading)
                              Center(
                                  child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20.h),
                                child: CircularProgressIndicator(),
                              ))
                            else
                              AppText(
                                _dailySummary,
                                style: AppFontStyles.bodyRegular12_180
                                    .copyWith(color: AppColors.grey900),
                              ),
                            Align(
                                alignment: Alignment.bottomRight,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: Size(133, 40),
                                    backgroundColor: AppColors.grey50,
                                    side: BorderSide(
                                        color: AppColors.grey200), // 테두리 색
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12), // 모서리 둥글게
                                    ),
                                    padding:
                                        EdgeInsets.symmetric(vertical: 9.5.h)
                                            .copyWith(left: 16.w, right: 10.w),
                                  ),
                                  onPressed: () {
                                    context.go("/report/chat",
                                        extra: _selectedDay);
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(AppTextStrings.checkChatHistory,
                                          style: AppFontStyles.bodyMedium14
                                              .copyWith(
                                                  color: AppColors.grey900)),
                                      SizedBox(width: 6.w),
                                      Icon(Icons.arrow_forward,
                                          color: AppColors.grey900, size: 18.r),
                                    ],
                                  ),
                                ))
                          ],
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.only(top: 76.h),
                        child: AppText(_dailySummary),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}
