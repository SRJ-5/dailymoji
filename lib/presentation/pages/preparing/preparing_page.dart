// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';

class PreparingPage extends StatelessWidget {
  PreparingPage(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true, // AppBar 뒤로 Body 확장
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0, // 그림자 지우기
        systemOverlayStyle: SystemUiOverlayStyle.dark, // 상태바 아이콘 검은색 만들기
        title: AppText(
          title,
          style: AppFontStyles.bodyBold18.copyWith(color: AppColors.grey900),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppImages.preparingImage,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                SizedBox(height: 250.h),
                AppText(
                  "곧 만나요!\n준비 중이에요",
                  textAlign: TextAlign.center,
                  style: AppFontStyles.heading2.copyWith(color: AppColors.grey900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
