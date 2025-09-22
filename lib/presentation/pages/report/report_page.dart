import 'package:dailymoji/presentation/pages/report/widgets/monthly_report.dart';
import 'package:dailymoji/presentation/pages/report/widgets/weekly_report.dart';
import 'package:flutter/material.dart';

// MODIFIED: 불필요한 위젯(BottomBar) 제거 및 구조 단순화. StatelessWidget -> ConsumerWidget으로 변경 가능하지만, 여기선 필요 없음.
class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Moji Report'),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
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
                WeeklyReport(), // MODIFIED: 위젯 이름 변경
              ]),
            )
          ],
        ),
      ),
      // bottomNavigationBar: BottomBar(), // 앱 전체 네비게이션은 메인 레이아웃에서 관리하는 것이 좋음
    );
  }
}
