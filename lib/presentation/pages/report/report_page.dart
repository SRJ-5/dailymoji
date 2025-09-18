import 'package:dailymoji/presentation/pages/report/widgets/monthly_report.dart';
import 'package:dailymoji/presentation/pages/report/widgets/two_weeks_report.dart';
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
              // 여기가 월간 탭에 대한 위젯. 즉, 달력 위젯
              MonthlyReport(),
              // 여기가 주간 탭에 대한 위젯. 즉, 그래프 위젯
              TwoWeeksReport()
            ]))
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(),
    );
  }
}
