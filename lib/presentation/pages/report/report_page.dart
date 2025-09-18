import 'package:dailymoji/presentation/pages/report/widgets/monthly_report.dart';
import 'package:dailymoji/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ReportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Moji Report'),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: '월간'),
                Tab(text: '주간'),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
            ),
            Expanded(
                child: TabBarView(children: [
              MonthlyReport(),
              TableCalendar(
                focusedDay: DateTime.now(),
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2099, 12, 31),
                calendarFormat: CalendarFormat.twoWeeks,
                availableCalendarFormats: const {
                  CalendarFormat.twoWeeks: '2주만',
                },
              )
            ]))
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(),
    );
  }
}
