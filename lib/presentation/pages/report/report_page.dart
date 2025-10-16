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

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _showTutorial = false;
  int _tutorialStep = 0; // 0: 모지달력 튜토리얼, 1: 모지차트 튜토리얼

  bool _calendarTutorialShown = false;
  bool _chartTutorialShown = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    // ✅ 탭 변경 리스너 (실제 탭 이동시에만 작동)
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return; // 이동 중에는 무시
      if (_tabController.index == 1 && !_chartTutorialShown) {
        setState(() {
          _tutorialStep = 1;
          _showTutorial = true;
          _chartTutorialShown = true;
        });
      }
    });

    // ✅ 초기 진입 시 모지 달력 튜토리얼만 표시
    Future.microtask(() {
      if (!_calendarTutorialShown) {
        setState(() {
          _tutorialStep = 0;
          _showTutorial = true;
          _calendarTutorialShown = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userViewModelProvider);

    return Stack(children: [
      Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.yellow50,
          centerTitle: true,
          title: AppText('리포트',
              style: AppFontStyles.heading3.copyWith(color: AppColors.grey900)),
        ),

        // ❌ 기존 DefaultTabController 제거
        // ✅ 직접 만든 _tabController 연결
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

      // ✅ 튜토리얼 오버레이 (화면 전체 덮음)
      if (_showTutorial)
        ReportTutorial(
          step: _tutorialStep,
          onClose: () {
            setState(() => _showTutorial = false);
          },
        ),
    ]);
  }
}
