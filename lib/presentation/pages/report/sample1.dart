// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';

// class Sample1 extends StatelessWidget {
//   const Sample1({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: AspectRatio(
//           aspectRatio: 2.0,
//           child: LineChart(
//             LineChartData(
//               lineBarsData: [
//                 LineChartBarData(
//                   spots: const [
//                     FlSpot(0, 0),
//                     FlSpot(1, 1),
//                     FlSpot(2, 1),
//                     FlSpot(3, 4),
//                     FlSpot(4, 5),
//                     FlSpot(10, 2),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class Sample1 extends StatelessWidget {
  const Sample1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("리포트",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 탭 메뉴
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text("모지 달력",
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.w500)),
                  SizedBox(width: 24),
                  Text("모지 차트",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // 라인 차트 박스
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text("나의 2주간 감정 상태",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 2,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text("12.6");
                                  case 2:
                                    return const Text("12.8");
                                  case 4:
                                    return const Text("12.10");
                                  case 6:
                                    return const Text("12.12");
                                  case 8:
                                    return const Text("12.14");
                                  case 10:
                                    return const Text("12.16");
                                  case 12:
                                    return const Text("12.18");
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        minX: 0,
                        maxX: 12,
                        minY: 0,
                        maxY: 10,
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: false,
                            color: Colors.green,
                            barWidth: 2,
                            spots: const [
                              FlSpot(0, 6),
                              FlSpot(2, 8),
                              FlSpot(4, 4),
                              FlSpot(6, 3),
                              FlSpot(8, 7),
                              FlSpot(10, 2),
                              FlSpot(12, 5),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text("종합 감정 점수",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

            // 종합 감정 점수 카드
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("종합 감정 점수",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _ScoreBox(
                          label: "평균 감정 점수", value: "6점", color: Colors.black),
                      _ScoreBox(
                          label: "최고 감정 점수", value: "8점", color: Colors.red),
                      _ScoreBox(
                          label: "최저 감정 점수", value: "3점", color: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "스트레스, 지속적 우울 3점과 상관있어요. 검사자는 최근 하루들이 그 내쉬는 것만으로도 마음이 쉽게 가라앉을 수 있어요. 자신에게 큰 수확을 선물해 보세요.",
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  )
                ],
              ),
            ),
          ],
        ),
      ),

      // 하단 네비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "리포트"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "마이"),
        ],
      ),
    );
  }
}

// 점수 박스 위젯
class _ScoreBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreBox(
      {required this.label,
      required this.value,
      required this.color,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
