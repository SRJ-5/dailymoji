import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class CounselingPage extends StatelessWidget {
  const CounselingPage({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.yellow50,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.yellow50,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.grey900),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: AppText(
          '전문 상담 연결',
          style: AppFontStyles.heading3.copyWith(color: AppColors.grey900),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            AppText(
              '지금 많이 힘드신가요?',
              style: AppFontStyles.bodyBold16.copyWith(color: AppColors.grey900),
            ),
            SizedBox(height: 12.h),

            // 설명 텍스트
            AppText(
              '이 앱은 의료 서비스가 아니기 때문에, 위급한 상황에서는 아래의 전문 상담 기관으로 바로 전화해 주세요.',
              style: AppFontStyles.bodyRegular14.copyWith(
                color: AppColors.grey900,
              ),
            ),
            SizedBox(height: 16.h),
            Divider(height: 1.h, color: AppColors.grey100),
            SizedBox(height: 16.h),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(top: 16.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.grey100, width: 1.sp),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 번호 안내 섹션
                  AppText(
                    '번호 안내',
                    style: AppFontStyles.bodyBold14.copyWith(color: AppColors.grey900),
                  ),
                  // 상담 기관 리스트
                  _CounselingItem(
                    name: '자살예방상담',
                    phone: '1393',
                    onTap: () => _makePhoneCall('1393'),
                  ),
                  Divider(height: 1.h, color: AppColors.grey100),
                  _CounselingItem(
                    name: '정신건강상담전화',
                    phone: '1577-0199',
                    onTap: () => _makePhoneCall('1577-0199'),
                  ),
                  Divider(height: 1.h, color: AppColors.grey100),
                  _CounselingItem(
                    name: '보건복지상담센터',
                    phone: '129',
                    onTap: () => _makePhoneCall('129'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounselingItem extends StatelessWidget {
  final String name;
  final String phone;
  final VoidCallback onTap;

  const _CounselingItem({
    required this.name,
    required this.phone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 상담 기관명과 전화번호
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                '$name($phone)',
                style: AppFontStyles.bodyRegular16.copyWith(
                  color: AppColors.grey700,
                ),
              ),
            ],
          ),

          // 즉시 전화하기 버튼
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: AppColors.yellow700,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: AppText(
                '즉시 전화하기',
                style: AppFontStyles.bodyMedium12.copyWith(
                  color: AppColors.grey50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
