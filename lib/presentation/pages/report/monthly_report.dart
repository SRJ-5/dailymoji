import 'dart:convert';
import 'package:dailymoji/core/config/api_config.dart';
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

  bool checkEmoji = false;

  String _dailySummary = "날짜를 선택하면 감정 요약을 볼 수 있어요.";
  bool _isSummaryLoading = false;

  /// 클러스터 코드를 한국어 라벨로 변환
  String clusterLabel(String code) {
    switch (code) {
      case 'neg_high':
        return '불안/분노';
      case 'neg_low':
        return '우울/무기력';
      case 'sleep':
        return '불규칙 수면';
      case 'ADHD':
        return '집중력저하';
      case 'positive':
      default:
        return '평온/회복';
    }
  }

  /// 점수를 100배 후 정수 반환 (반올림)
  int displayScore100(double score) => (score * 100).round();

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
      for (final r in rows) {
        final local = r.createdAt.toLocal();
        if (local.year == sd.year &&
            local.month == sd.month &&
            local.day == sd.day) {
          selectedRow = r;
          break;
        }
      }
    }

    // 요약 카드 제목 문구
    final summaryTitle = (selectedRow == null)
        ? "이 날은 기록이 없는 하루예요"
        : "이 날의 ${clusterLabel(selectedRow.cluster)} 감정이 "
            "${displayScore100(selectedRow.score)}점으로 가장 강렬했습니다.";

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
                    checkEmoji = path == null ? false : true;
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
                              child: Text(
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
                error: (e, _) => Text('로드 실패: $e'),
                data: (_) => const SizedBox.shrink(),
              ),

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

              SizedBox(height: 8.h),

              // 감정 요약 카드 (현재는 더미, 나중에 선택일 기반 상세 연결)
              if (_selectedDay != null)
                checkEmoji
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
                            Text(summaryTitle,
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
                              Text(
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
                                      Text('채팅 확인하기',
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
                        child: Text("이 날은 기록이 없는 하루예요"),
                      ),
            ],
          ),
        ),
      ),
    );
  }

// _MonthlyReportState 안에 추가
  Future<void> _fetchDailySummary(DateTime date) async {
    if (widget.userId.isEmpty) return;

    setState(() {
      _isSummaryLoading = true;
      _dailySummary = "감정 기록을 요약하고 있어요...";
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/report/summary'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'date': DateFormat('yyyy-MM-dd').format(date),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _dailySummary = data['summary'];
        });
      } else {
        setState(() {
          _dailySummary = "요약을 불러오는 데 실패했어요.";
        });
      }
    } catch (e) {
      setState(() {
        _dailySummary = "오류가 발생했어요: $e";
      });
    } finally {
      setState(() {
        _isSummaryLoading = false;
      });
    }
  }
}
