import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/my/pin_password_setting/widgets/password_change_modal.dart';
import 'package:dailymoji/presentation/pages/my/widgets/build_section.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PinPasswordSetting extends StatefulWidget {
  @override
  State<PinPasswordSetting> createState() =>
      _PinPasswordSettingState();
}

class _PinPasswordSettingState
    extends State<PinPasswordSetting> {
  bool _isPasswordEnabled = false;

  void _showPasswordChangeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isDismissible: true,
      enableDrag: false,
      builder: (context) => PasswordChangeModal(
        isChangePassword: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, VoidCallback> passwordsetting = {
      AppTextStrings.pinPassword: () {},
      AppTextStrings.pinPasswordChange: _isPasswordEnabled
          ? () {
              _showPasswordChangeModal(context);
            }
          : () {}, // 토글이 꺼져있으면 아무것도 안 함
    };

    return Scaffold(
      backgroundColor: AppColors.yellow50,
      appBar: AppBar(
        backgroundColor: AppColors.yellow50,
        centerTitle: true,
        title: AppText(
          AppTextStrings.pinPassword,
          style: AppFontStyles.heading3,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Column(
          children: [
            SizedBox(
              height: 16.h,
            ),
            BuildSection(
              title: null,
              items: passwordsetting.keys.toList(),
              onTapList: passwordsetting.values.toList(),
              widgets: [
                Toggle(
                  initialValue: _isPasswordEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isPasswordEnabled = value;
                    });
                  },
                ),
                null, // 암호 변경은 기본 아이콘 사용
              ],
              textColors: [
                null, // 암호 설정은 기본 색상
                _isPasswordEnabled
                    ? AppColors.grey700
                    : AppColors.grey300, // 암호 변경은 토글 상태에 따라
              ],
            )
          ],
        ),
      ),
    );
  }
}
