import 'package:dailymoji/domain/entities/report_record.dart';
import 'package:dailymoji/presentation/pages/report/report_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

// MODIFIED: StatelessWidget -> ConsumerStatefulWidget으로 변경하여 상태 관리
class MonthlyReport extends ConsumerStatefulWidget {
  const MonthlyReport({super.key});

  @override
  ConsumerState<MonthlyReport> createState() => _MonthlyReportState();
}

class _MonthlyReportState extends ConsumerState<MonthlyReport> {
  // 날짜별로 기록된 데이터를 매핑
  Map<DateTime, List<ReportRecord>> getEventsForDay(
      DateTime day, List<ReportRecord> records) {
    final Map<DateTime, List<ReportRecord>> events = {};
    for (var record in records) {
      final dateKey =
          DateTime.utc(record.date.year, record.date.month, record.date.day);
      if (events[dateKey] == null) {
        events[dateKey] = [];
      }
      events[dateKey]!.add(record);
    }
    return events;
  }

  // 감정 클러스터 이름에 따라 아이콘 경로 반환
  String _getEmotionIconPath(String emotion) {
    switch (emotion) {
      case 'neg_low':
        return 'assets/images/crying.png';
      case 'neg_high':
        return 'assets/images/angry.png';
      case 'adhd_high':
        return 'assets/images/shocked.png';
      case 'sleep':
        return 'assets/images/sleeping.png';
      case 'positive':
        return 'assets/images/smile.png';
      default:
        return 'assets/icons/emotion.png'; // 기본 아이콘
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportViewModelProvider);
    final reportNotifier = ref.read(reportViewModelProvider.notifier);

    // 현재 포커스된 달의 기록만 가져옴
    final recordsForMonth =
        reportState.monthlyRecords[reportState.focusedMonth] ?? [];
    final events = getEventsForDay(reportState.focusedMonth, recordsForMonth);

    return TableCalendar<ReportRecord>(
      focusedDay: reportState.focusedMonth,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2099, 12, 31),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      // 사용자가 달을 변경할 때마다 ViewModel에 알려 새 데이터를 가져오게 함
      onPageChanged: (focusedDay) {
        final newMonth = DateTime(focusedDay.year, focusedDay.month);
        reportNotifier.fetchRecordsForMonth(newMonth);
      },
      // 이벤트 로더: 특정 날짜에 어떤 기록이 있는지 알려줌
      eventLoader: (day) {
        return events[DateTime.utc(day.year, day.month, day.day)] ?? [];
      },
      calendarBuilders: CalendarBuilders(
        headerTitleBuilder: (context, day) {
          return Center(
              child: Text(
            '${day.month}월',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ));
        },
        // 마커(아이콘) 빌더
        markerBuilder: (context, day, events) {
          if (events.isNotEmpty) {
            // 그날의 첫 번째 기록의 대표 감정을 아이콘으로 표시
            final dominantEmotion = events.first.dominantEmotion;
            return Positioned(
              bottom: 1,
              child: Image.asset(
                _getEmotionIconPath(dominantEmotion),
                width: 20,
                height: 20,
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
