import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';

const String angryImage = "assets/images/emoticon/emo_3d_angry_02.png";
const String cryingImage = "assets/images/emoticon/emo_3d_crying_02.png";
const String shockedImage = "assets/images/emoticon/emo_3d_shocked_02.png";
const String sleepingImage = "assets/images/emoticon/emo_3d_sleeping_02.png";
const String smileImage = "assets/images/emoticon/emo_3d_smile_02.png";

// 현재 기분 상태 (예시: Riverpod)
final currentMoodProvider = StateProvider<String>((ref) {
  return "angry";
});

class Test2 extends StatefulWidget {
  const Test2({super.key});

  @override
  State<Test2> createState() => _Test2State();
}

class _Test2State extends State<Test2> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 날짜별 감정 아이콘 매핑 (예시)
  final Map<DateTime, Image> _emotions = {
    DateTime.utc(2025, 9, 16): Image.asset(angryImage),
    DateTime.utc(2025, 9, 1): Image.asset(cryingImage),
    DateTime.utc(2025, 9, 4): Image.asset(shockedImage),
    DateTime.utc(2025, 9, 5): Image.asset(sleepingImage),
    DateTime.utc(2025, 9, 6): Image.asset(smileImage),
    DateTime.utc(2025, 9, 22): Image.asset(angryImage),
  };

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 오늘 날짜 선택
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.yellow50,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Column(
          children: [
            // 📅 달력
            TableCalendar(
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

              // 📌 헤더 스타일
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.grey),
              ),

              // 📌 요일 스타일
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
                weekendStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),

              // 📌 달력 기본 스타일 (선택 색상은 제거)
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                weekendTextStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.orange600, // 오늘 날짜 강조
                  shape: BoxShape.circle,
                ),
              ),

              // 📌 날짜 커스텀 빌더
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  if (_emotions.containsKey(day)) {
                    return Center(child: _emotions[day]);
                  }
                  return Center(
                    child: Text(
                      '${day.day}',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  return Container(
                    height: 32.h,
                    width: 32.w,
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
                  "${_selectedDay!.year}년 ${_selectedDay!.month}월 ${_selectedDay!.day}일",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 12),

            // 감정 요약 카드
            if (_selectedDay != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "이날 기록된 감정을 요약했어요",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "반복되는 업무 스트레스와 주변의 기대 때문에 마음이 무거운 하루였어요. "
                      "친구와의 짧은 대화가 위로가 되었어요. 혼자만의 시간을 꼭 가지며 마음을 돌보길 해요.",
                    ),
                    Container(
                      height: 40.h,
                      width: 133.w,
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 9.5.h),
                      decoration: ShapeDecoration(
                        color: AppColors.green400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '채팅 확인하기',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              height: 1.50,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
