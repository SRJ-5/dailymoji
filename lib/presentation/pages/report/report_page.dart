import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/pages/report/weekly_report.dart';
import 'package:dailymoji/presentation/pages/report/monthly_report.dart';
import 'package:dailymoji/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dailymoji/presentation/pages/report/widget/report_tutorial.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCalendarSeenKey = 'report_tutorial_calendar_seen_v1';
const _kChartSeenKey = 'report_tutorial_chart_seen_v1';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 튜토리얼 제어
  bool _showTutorial = false;
  int _tutorialStep = 0; // 0: 모지달력 튜토리얼, 1: 모지차트 튜토리얼

  // 영구 저장된 "본 적 있음" 플래그
  bool _calendarSeen = false;
  bool _chartSeen = false;

  // 초기 로딩 끝났는지
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 탭 변경 리스너: 차트 탭으로 이동했을 때만 체크
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return; // 스와이프 중 ignore
      if (!mounted) return;
      if (_tabController.index == 1 && !_chartSeen && !_showTutorial) {
        // 차트 튜토리얼 최초 1회만 표시
        setState(() {
          _tutorialStep = 1;
          _showTutorial = true;
        });
      }
    });

    _initPrefs();
  }

  Future<void> _initPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _calendarSeen = prefs.getBool(_kCalendarSeenKey) ?? false;
    _chartSeen = prefs.getBool(_kChartSeenKey) ?? false;

    if (!mounted) return;
    setState(() {
      _loaded = true;
      // 첫 진입 시: 달력 튜토리얼이 아직 안 보였으면 띄움
      if (!_calendarSeen) {
        _tutorialStep = 0;
        _showTutorial = true;
      }
    });
  }

  // // 개발자용 튜토리얼 리셋 버튼 (삭제하지 말것)
  // Future<void> resetReportTutorials() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove(_kCalendarSeenKey);
  //   await prefs.remove(_kChartSeenKey);
  // }

  Future<void> _handleTutorialClose() async {
    if (!mounted) return;
    setState(() => _showTutorial = false);

    // 누른 순간에만 '봤다' 저장
    final prefs = await SharedPreferences.getInstance();
    if (_tutorialStep == 0 && !_calendarSeen) {
      _calendarSeen = true;
      await prefs.setBool(_kCalendarSeenKey, true);
    } else if (_tutorialStep == 1 && !_chartSeen) {
      _chartSeen = true;
      await prefs.setBool(_kChartSeenKey, true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userViewModelProvider);

    if (!_loaded) {
      return Scaffold(
        body: Center(
          child: Container(
            height: double.infinity,
            width: double.infinity,
            color: AppColors.yellow50,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.green400,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(children: [
      Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.yellow50,
          centerTitle: true,
          title: AppText('리포트',
              style: AppFontStyles.heading3.copyWith(color: AppColors.grey900)),
          // 개발자용 튜토리얼 리셋 버튼 (삭제하지 말것)
          // actions: [
          //   GestureDetector(
          //     onTap: () {
          //       resetReportTutorials();
          //     },
          //     child: Container(
          //       color: Colors.red,
          //       child: Text(
          //         "튜토리얼 리셋",
          //         style: TextStyle(color: Colors.white),
          //       ),
          //     ),
          //   )
          // ],
        ),
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              color: AppColors.yellow50,
              child: TabBar(
                controller: _tabController,
                textScaler: TextScaler.noScaling,
                tabs: const [
                  Tab(text: '모지 달력'),
                  Tab(text: '모지 차트'),
                ],
                labelColor: AppColors.green500,
                unselectedLabelColor: AppColors.grey500,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 2.5,
                    color: AppColors.green500,
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: AppFontStyles.bodySemiBold14
                    .copyWith(color: AppColors.green500),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  MonthlyReport(userId: userProfile.userProfile!.id!),
                  WeeklyReport(userId: userProfile.userProfile!.id!),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(),
      ),

      // 튜토리얼 오버레이
      if (_showTutorial)
        ReportTutorial(
          step: _tutorialStep,
          onClose: _handleTutorialClose,
        ),
    ]);
  }
}
