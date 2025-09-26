import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';

// 현재 기분 상태 : 여기에 최고 점수의 감정상태를 관리하고
// 12시가 넘어갈때 달력에 표시되는 로직으로 구현하면 될듯합니다
// 현재로썬 아무대도 안쓰여서 다른식으로 만드실거면 삭제해도 무방합니다
final currentMoodProvider = StateProvider<String>((ref) {
  return "";
});

class MonthlyReport extends StatefulWidget {
  const MonthlyReport({super.key});

  @override
  State<MonthlyReport> createState() => _MonthlyReportState();
}

class _MonthlyReportState extends State<MonthlyReport> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 날짜별 감정 데이터 (예시) // 나중엔 실제 데이터로 교체
  final Map<DateTime, Image> _emotions = {
    DateTime.utc(2025, 9, 16): Image.asset(AppImages.angryEmoji),
    DateTime.utc(2025, 9, 1): Image.asset(AppImages.cryingEmoji),
    DateTime.utc(2025, 9, 4): Image.asset(AppImages.shockedEmoji),
    DateTime.utc(2025, 9, 5): Image.asset(AppImages.sleepingEmoji),
    DateTime.utc(2025, 9, 6): Image.asset(AppImages.smileEmoji),
    DateTime.utc(2025, 9, 22): Image.asset(AppImages.angryEmoji),
  };

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 오늘 날짜 선택
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return Scaffold(
      backgroundColor: AppColors.yellow50,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Column(
          children: [
            // 달력
            TableCalendar(
              daysOfWeekHeight: 36.h,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },

              // 헤더 스타일
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) {
                  // 타이틀 내용을 원하는 형태로 변환
                  return "${date.year}년 ${date.month}월";
                },
                titleTextStyle: AppFontStyles.bodyMedium14.copyWith(
                  color: AppColors.grey900,
                ),
                leftChevronIcon:
                    const Icon(Icons.chevron_left, color: AppColors.grey900),
                rightChevronIcon:
                    const Icon(Icons.chevron_right, color: AppColors.grey900),
              ),

              // 달력 기본 스타일 (선택 색상은 제거)
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: true,
                todayDecoration: BoxDecoration(
                  color: AppColors.orange600, // 오늘 날짜 강조
                  shape: BoxShape.circle,
                ),
              ),

              // 날짜 커스텀 빌더
              calendarBuilders: CalendarBuilders(
                // 요일 스타일
                dowBuilder: (context, day) {
                  return Center(
                    child: Text(weekdays[day.weekday % 7],
                        style: AppFontStyles.bodyMedium14
                            .copyWith(color: AppColors.grey900)),
                  );
                },
                defaultBuilder: (context, day, focusedDay) {
                  if (_emotions.containsKey(day)) {
                    return Center(
                      child: SizedBox(
                          height: 28.h, width: 28.w, child: _emotions[day]),
                    );
                  }
                  return SizedBox(
                    width: 40.w,
                    height: 40.h,
                    child: Center(
                      child: Text('${day.day}'),
                    ),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  return Container(
                    height: 40.h,
                    width: 40.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.orange600, // 오늘 날짜 강조
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: AppFontStyles.bodySemiBold14
                          .copyWith(color: AppColors.grey50),
                    ),
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  return Container(
                    height: 40.h,
                    width: 40.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.orange100, // 선택된 날짜 강조
                      border: Border.all(color: AppColors.orange600, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: _emotions.containsKey(day)
                        ? _emotions[day]
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

            // 선택된 날짜 텍스트
            if (_selectedDay != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${_selectedDay!.month}월 ${_selectedDay!.day}일 ${weekdays[_selectedDay!.weekday]}요일",
                  style: AppFontStyles.bodyBold16
                      .copyWith(color: AppColors.grey900),
                ),
              ),

            const SizedBox(height: 12),

            // 감정 요약 카드
            if (_selectedDay != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppColors.green100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.green200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("이날 기록된 감정을 요약했어요",
                        style: AppFontStyles.bodyBold14
                            .copyWith(color: AppColors.green700)),
                    SizedBox(height: 6.h),
                    Text(
                        "반복되는 업무 스트레스와 주변의 기대 때문에 마음이 무거운 하루였어요. "
                        "친구와의 짧은 대화가 위로가 되었어요. 혼자만의 시간을 꼭 가지며 마음을 돌보길 해요.",
                        style: AppFontStyles.bodyRegular12_180
                            .copyWith(color: AppColors.grey900)),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: () {}, // _selectedDay를 가지고 채팅 페이지로 이동!!!
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
                              Icon(
                                Icons.arrow_forward,
                                color: AppColors.grey900,
                                size: 18.r,
                              ),
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
}
