import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class MonthlyReport extends StatelessWidget {
  const MonthlyReport({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      focusedDay: DateTime.now(),
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2099, 12, 31),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarBuilders: CalendarBuilders(
        headerTitleBuilder: (context, day) {
          return Center(
              child: Text(
            '${day.month}월',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ));
        },
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
                'Sun',
                style: TextStyle(color: Colors.blueAccent),
              ),
            );
          }
        },
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
            Column(
              children: [
                Center(
                  child: Text('${day.day}'),
                ),
                // TODO: 여기 조건에 감정이 있으면 으로 넣어서 사용하도록 변경하기
                day.weekday != DateTime.saturday
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
