import 'package:dailymoji/core/providers.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class BottomBar extends ConsumerWidget {
  const BottomBar({super.key});

  static const List<String> _routes = [
    '/home',
    '/report',
    '/my'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Theme(
      // 터치 이펙트 제거
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      child: Container(
        height: 100.h,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // 그림자 색
              blurRadius: 3, // 번짐 정도
              offset: const Offset(0, -2), // 위로 그림자
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex, // location 기반 index
          onTap: (index) {
            // 이미 같은 탭을 눌렀다면 다시 이동할 필요 없음
            if (index != currentIndex) {
              ref.read(bottomNavIndexProvider.notifier).state =
                  index;
              context.go(_routes[index]);
            }
          },
          iconSize: 24.r,
          selectedItemColor: AppColors.green500,
          unselectedItemColor: AppColors.grey700,
          backgroundColor: AppColors.yellow50,
          selectedLabelStyle: AppFontStyles.bodyMedium14,
          unselectedLabelStyle: AppFontStyles.bodyMedium14,
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                AppIcons.home,
                colorFilter: ColorFilter.mode(
                    currentIndex == 0
                        ? AppColors.green500
                        : AppColors.grey700,
                    BlendMode.srcIn),
              ),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                AppIcons.report,
                colorFilter: ColorFilter.mode(
                    currentIndex == 1
                        ? AppColors.green500
                        : AppColors.grey700,
                    BlendMode.srcIn),
              ),
              label: "리포트",
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                AppIcons.my,
                colorFilter: ColorFilter.mode(
                    currentIndex == 2
                        ? AppColors.green500
                        : AppColors.grey700,
                    BlendMode.srcIn),
              ),
              label: "마이",
            ),
          ],
        ),
      ),
    );
  }
}
