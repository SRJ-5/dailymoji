import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class BottomBar extends ConsumerWidget {
  const BottomBar({super.key});

  static const List<String> _routes = [
    '/home',
    '/home/report',
    '/home/my'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
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
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/icons/home.png')),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon:
                ImageIcon(AssetImage('assets/icons/report.png')),
            label: "리포트",
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage('assets/icons/my.png')),
            label: "마이",
          ),
        ],
      ),
    );
  }
}
