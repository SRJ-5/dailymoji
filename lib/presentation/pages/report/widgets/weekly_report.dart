import 'package:dailymoji/domain/entities/report_record.dart';
import 'package:dailymoji/presentation/pages/report/report_view_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class WeeklyReport extends ConsumerWidget {
  const WeeklyReport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(reportViewModelProvider);

    if (reportState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 최근 2주치 데이터를 모음
    final allRecords =
        reportState.monthlyRecords.values.expand((list) => list).toList();
    final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
    final recentRecords =
        allRecords.where((r) => r.date.isAfter(twoWeeksAgo)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('최근 2주간 G-Score 변화',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: recentRecords.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(right: 16.0, top: 16.0),
                    child: LineChart(_buildLineChartData(recentRecords)),
                  )
                : const Center(child: Text("표시할 데이터가 없습니다.")),
          ),
          const SizedBox(height: 40),
          const Text('가장 자주 기록된 감정',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildEmotionFrequency(recentRecords),
        ],
      ),
    );
  }

  Widget _buildEmotionFrequency(List<ReportRecord> records) {
    if (records.isEmpty) return const Text('기록이 없습니다.');

    final Map<String, int> frequency = {};
    for (var record in records) {
      final emotion = record.dominantEmotion;
      frequency[emotion] = (frequency[emotion] ?? 0) + 1;
    }

    final sortedEntries = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 감정 이름 한글로 변환
    String toKorean(String emotion) {
      switch (emotion) {
        case 'neg_low':
          return '우울/무기력';
        case 'neg_high':
          return '불안/분노';
        case 'adhd_high':
          return '산만함';
        case 'sleep':
          return '수면 문제';
        case 'positive':
          return '긍정';
        default:
          return '기타';
      }
    }

    return Column(
      children: sortedEntries
          .take(3)
          .map((entry) => ListTile(
                leading:
                    const Icon(Icons.favorite_border, color: Colors.pinkAccent),
                title: Text(toKorean(entry.key),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text('${entry.value}회'),
              ))
          .toList(),
    );
  }

  LineChartData _buildLineChartData(List<ReportRecord> records) {
    // 날짜별 G-Score 평균 계산
    final Map<DateTime, List<double>> dailyScores = {};
    for (var record in records) {
      final dateKey =
          DateTime(record.date.year, record.date.month, record.date.day);
      if (dailyScores[dateKey] == null) dailyScores[dateKey] = [];
      dailyScores[dateKey]!.add(record.gScore);
    }
    final List<MapEntry<DateTime, double>> dailyAverageData =
        dailyScores.entries.map((entry) {
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      return MapEntry(entry.key, average);
    }).toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    final spots = dailyAverageData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1, // 모든 지점에 타이틀을 표시하도록 시도
            getTitlesWidget: (value, meta) {
              // ✅✅✅ 여기가 수정된 부분입니다 ✅✅✅
              final index = value.toInt();
              if (index < 0 || index >= dailyAverageData.length) {
                return const SizedBox.shrink();
              }

              // 데이터가 너무 촘촘할 경우, 3일에 한 번씩만 라벨 표시 (조절 가능)
              if (dailyAverageData.length > 7 && index % 3 != 0) {
                return const SizedBox.shrink();
              }

              final date = dailyAverageData[index].key;

              // SideTitleWidget 없이 Text 위젯을 바로 반환합니다.
              return Text(
                DateFormat('M/d').format(date),
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
          show: true, border: Border.all(color: Colors.grey.shade300)),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData:
              BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
        ),
      ],
      minY: 0,
      maxY: 1, // G-Score는 0~1 사이
    );
  }
}
