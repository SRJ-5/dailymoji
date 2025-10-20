import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailymoji/presentation/providers/background_provider.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 배경 선택 페이지
class BackgroundSettingPage extends ConsumerStatefulWidget {
  const BackgroundSettingPage({super.key});

  @override
  ConsumerState<BackgroundSettingPage> createState() =>
      _BackgroundSelectPageState();
}

class _BackgroundSelectPageState extends ConsumerState<BackgroundSettingPage> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentIndex = 0;

  // ✅ 사용할 배경 이미지 목록 (AppImages 값 사용)
  final List<String> backgrounds = [
    AppImages.bgHouse,
    AppImages.bgRain,
    AppImages.bgSnow,
    AppImages.bgForest,
  ];

  @override
  Widget build(BuildContext context) {
    final bgNotifier = ref.read(backgroundImageProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ 전체 페이지 뷰 (배경 미리보기)
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: backgrounds.length,
            itemBuilder: (context, index) {
              final path = backgrounds[index];
              return Image.asset(
                path,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),

          // ✅ 좌우 화살표 버튼
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              iconSize: 28.sp,
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
              onPressed: () {
                if (_currentIndex > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              iconSize: 28.sp,
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
              onPressed: () {
                if (_currentIndex < backgrounds.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),

          // ✅ 상단 “선택 완료” 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 12.h,
            right: 20.w,
            child: GestureDetector(
              onTap: () async {
                final selectedPath = backgrounds[_currentIndex];
                await bgNotifier.setBackground(selectedPath);
                if (context.mounted) Navigator.pop(context);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '선택완료',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // ✅ 하단 페이지 인디케이터 (점 표시)
          Positioned(
            bottom: 40.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                backgrounds.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: _currentIndex == index ? 10.w : 6.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
