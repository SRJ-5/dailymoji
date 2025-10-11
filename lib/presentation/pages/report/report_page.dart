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

// MODIFIED: 불필요한 위젯(BottomBar) 제거 및 구조 단순화. StatelessWidget -> ConsumerWidget으로 변경 가능하지만, 여기선 필요 없음.
class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserProfile = ref.watch(userViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.yellow50,
        centerTitle: true,
        title: AppText('리포트',
            style: AppFontStyles.heading3
                .copyWith(color: AppColors.grey900)),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              color: AppColors.yellow50,
              child: TabBar(
                textScaler: TextScaler.noScaling,
                tabs: [
                  Tab(text: '모지 달력'),
                  Tab(text: '모지 차트'),
                ],
                labelColor: AppColors.green500,
                unselectedLabelColor: AppColors.grey500,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 2.5, // 밑줄 두께
                    color: AppColors.green500, // 선택된 탭 밑줄 색상
                  ),
                ),
                indicatorSize:
                    TabBarIndicatorSize.tab, // 탭 너비만큼 underline
                labelStyle: AppFontStyles.bodySemiBold14
                    .copyWith(color: AppColors.green500),
              ),
            ),
            Expanded(
              child: TabBarView(children: [
                MonthlyReport(
                    userId: UserProfile.userProfile!.id!),
                WeeklyReport(
                    userId: UserProfile
                        .userProfile!.id!), // MODIFIED: 위젯 이름 변경
              ]),
            )
          ],
        ),
      ),
      bottomNavigationBar:
          BottomBar(), // 앱 전체 네비게이션은 메인 레이아웃에서 관리하는 것이 좋음
    );
  }
}
