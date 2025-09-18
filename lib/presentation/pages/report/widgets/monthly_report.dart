import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class MonthlyReport extends StatelessWidget {
  const MonthlyReport({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      // 선택된 날짜 = 현재 날짜
      focusedDay: DateTime.now(),
      // 최소로 보여줄 수 있는 날짜 및 최대로 보여줄 수 있는 날짜
      // lastDay를 몇 천년 뒤로 설정하면 initial rendering 시 연산량이 많아질 수 있다고 하여 일단 2099로 함
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2099, 12, 31),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarBuilders: CalendarBuilders(
        // 월 부분 커스텀 => 현재 0월로 표시되게 함
        headerTitleBuilder: (context, day) {
          return Center(
              child: Text(
            '${day.month}월',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ));
        },
        // 요일 부분 일요일과 토요일은 빨간색과 파란색으로 표시되도록 커스텀 설정
        dowBuilder: (context, day) {
          if (day.weekday == DateTime.sunday) {
            return Center(
              child: Text(
                'Sun',
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (day.weekday == DateTime.saturday) {
            return Center(
              child: Text(
                'Sat',
                style: TextStyle(color: Colors.blueAccent),
              ),
            );
          }
        },
        // 달력에 표시되는 날짜가 일요일, 또는 토요일이면 빨간색 또는 파란색으로 표시되도록 커스텀 설정
        // 추가로 날짜 밑에 이모티콘이 들어가는 로직도 설정
        defaultBuilder: (context, day, focusedDay) {
          if (day.weekday == DateTime.sunday) {
            return Column(
              children: [
                Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                // TODO: 여기 조건에 감정이 있으면 으로 넣어서 사용하도록 변경하기
                day.weekday == DateTime.sunday
                    ? Center(
                        child: Image.asset(
                          'assets/icons/emotion.png',
                          scale: 1.4,
                        ),
                      )
                    : SizedBox.shrink()
              ],
            );
          } else if (day.weekday == DateTime.saturday) {
            return Column(
              children: [
                Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
                // TODO: 여기 조건에 감정이 있으면 으로 넣어서 사용하도록 변경하기
                day.weekday == DateTime.saturday
                    ? Center(
                        child: Image.asset(
                          'assets/icons/emotion.png',
                          scale: 1.4,
                        ),
                      )
                    : SizedBox.shrink()
              ],
            );
          } else {
            return Column(
              children: [
                Center(
                  child: Text('${day.day}'),
                ),
                // TODO: 여기 조건에 감정이 있으면 으로 넣어서 사용하도록 변경하기
                day.weekday == DateTime.wednesday
                    ? Center(
                        child: Image.asset(
                          'assets/icons/emotion.png',
                          scale: 1.4,
                        ),
                      )
                    : SizedBox.shrink()
              ],
            );
          }
        },
      ),
    );
  }
}
