import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/pages/pin_password/widgets/password_change_modal.dart';
import 'package:dailymoji/presentation/pages/my/widgets/build_section.dart';
import 'package:dailymoji/presentation/pages/pin_password/pin_password_view_model.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinPasswordSetting extends ConsumerStatefulWidget {
  @override
  ConsumerState<PinPasswordSetting> createState() =>
      _PinPasswordSettingState();
}

class _PinPasswordSettingState
    extends ConsumerState<PinPasswordSetting> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isPinSet = ref
          .read(pinPasswordViewModelProvider)
          .isPasswordEnabled;
      if (isPinSet) {
        _showPasswordChangeModal(
          context: context,
          isChangePassword: false,
          isAuthenticated: true,
        );
      }
    });
  }

  void _showPasswordChangeModal(
      {required BuildContext context,
      required bool isChangePassword,
      required bool isAuthenticated}) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isDismissible: true,
      enableDrag: false,
      builder: (context) => PasswordChangeModal(
        isChangePassword: isChangePassword,
        isAuthenticated: isAuthenticated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(pinPasswordViewModelProvider);
    final pinVM =
        ref.read(pinPasswordViewModelProvider.notifier);
    bool isPasswordEnabled = pinState.isPasswordEnabled;
    final Map<String, VoidCallback> passwordsetting = {
      AppTextStrings.pinPassword: () {},
      AppTextStrings.pinPasswordChange: isPasswordEnabled
          ? () {
              _showPasswordChangeModal(
                  context: context,
                  isChangePassword: true,
                  isAuthenticated: true);
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
                  initialValue: isPasswordEnabled,
                  onChanged: (value) async {
                    if (value == false) {
                      await pinVM.deletePinNum();
                      await pinVM.hasPin();
                    } else {
                      _showPasswordChangeModal(
                          context: context,
                          isChangePassword: true,
                          isAuthenticated: true);

                      // if (isSuccess != true) {
                      //   setState(() {});
                      //   return;
                      // }
                    }
                    await pinVM.hasPin(); // state 업데이트
                  },
                ),
                null, // 암호 변경은 기본 아이콘 사용
              ],
              textColors: [
                null, // 암호 설정은 기본 색상
                isPasswordEnabled
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
