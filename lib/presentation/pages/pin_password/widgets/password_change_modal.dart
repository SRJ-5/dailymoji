import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/icons.dart';
import 'package:dailymoji/presentation/pages/pin_password/pin_password_view_model.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class PasswordChangeModal extends ConsumerStatefulWidget {
  final bool isChangePassword;
  final bool isAuthenticated;
  PasswordChangeModal(
      {required this.isChangePassword,
      required this.isAuthenticated});
  @override
  ConsumerState<PasswordChangeModal> createState() =>
      _PasswordChangeModalState();
}

class _PasswordChangeModalState
    extends ConsumerState<PasswordChangeModal> {
  bool? isCheckPassword;
  bool isCorrectPassword = true;

  Future<void> _selectPassword(String password) async {
    final pinVM =
        ref.read(pinPasswordViewModelProvider.notifier);
    isCheckPassword = await pinVM.selectedPinNum(
        password: password,
        isChangePin: widget.isChangePassword);
    print('암호 확인 체크 : $isCheckPassword');
    if (isCheckPassword == false) {
      Future.delayed(
        Duration(milliseconds: 200),
        () {
          isCorrectPassword = isCheckPassword!;
          pinVM.reStartPinNum();
          return;
        },
      );
    } else if (isCheckPassword == true &&
        widget.isChangePassword == false &&
        widget.isAuthenticated == false) {
      Future.delayed(
        Duration(milliseconds: 200),
        () {
          context.go('/home');
          pinVM.clearAllPinNum();
          return;
        },
      );
    } else if (isCheckPassword == true &&
        widget.isChangePassword == true &&
        widget.isAuthenticated == true) {
      Future.delayed(
        Duration(milliseconds: 200),
        () {
          context.pop();
          pinVM.clearAllPinNum();
          return;
        },
      );
    } else if (isCheckPassword == true &&
        widget.isChangePassword == false &&
        widget.isAuthenticated == true) {
      Future.delayed(
        Duration(milliseconds: 200),
        () {
          context.pop();
          pinVM.clearAllPinNum();
          return;
        },
      );
    }
  }

  void _deletePassword() {
    print('delete');
    ref
        .read(pinPasswordViewModelProvider.notifier)
        .clearPinNum();
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final appBarHeight = AppBar().preferredSize.height;
    final screenHeight = MediaQuery.of(context).size.height;
    // 전 페이지 AppBar는 그대로 보이고, 그 아래 body 영역까지만 덮기
    final bodyHeight =
        screenHeight - statusBarHeight - appBarHeight;

    final password =
        ref.watch(pinPasswordViewModelProvider).pinNum;
    final reWritePassword = ref
        .watch(pinPasswordViewModelProvider)
        .reCheckSavePinNum
        .isNotEmpty;
    final List<int> password1 = [1, 2, 3, 4];
    final List<String> keyPad = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '',
      '0',
      ''
    ];

    return Container(
      height: widget.isAuthenticated ? bodyHeight : screenHeight,
      width: double.infinity,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.yellow50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          PreferredSize(
            preferredSize: Size.fromHeight(appBarHeight),
            child: AppBar(
              scrolledUnderElevation: 0,
              backgroundColor: AppColors.yellow50,
              leading: widget.isAuthenticated == false &&
                      widget.isChangePassword == false
                  ? null
                  : BackButton(
                      onPressed: () {
                        ref
                            .read(pinPasswordViewModelProvider
                                .notifier)
                            .clearAllPinNum();
                        if (widget.isAuthenticated == true &&
                            widget.isChangePassword == false) {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
            ),
          ),
          SizedBox(height: 48.h),
          Column(
            children: [
              AppText(AppTextStrings.insertPassword,
                  style: AppFontStyles.heading1
                      .copyWith(color: AppColors.grey900)),
              SizedBox(height: 5),
              AppText(
                  widget.isChangePassword == true
                      ? isCorrectPassword == false
                          ? AppTextStrings.passwordErrorMessage
                          : reWritePassword
                              ? AppTextStrings
                                  .reCheckNewPasswordGuid
                              : AppTextStrings.newPasswordGuide
                      : isCorrectPassword == false
                          ? AppTextStrings.passwordErrorMessage
                          : AppTextStrings.passwordGuide,
                  style: AppFontStyles.bodyRegular16.copyWith(
                      color: isCorrectPassword == false
                          ? AppColors.noti100
                          : AppColors.grey900)),
              SizedBox(height: 25.h),
              SizedBox(
                height: 24.r,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) {
                      return Row(
                        children: [
                          selectedPassword(
                              index: index,
                              passwordLength: password.length),
                          index == 3
                              ? SizedBox.shrink()
                              : SizedBox(
                                  width: 25.w,
                                )
                        ],
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 40.h),
              Column(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 34.w),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: keyPad.length,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1),
                      itemBuilder: (context, index) {
                        return Container(
                          width: 40.r,
                          height: 40.r,
                          padding: EdgeInsets.all(12),
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: index == 9
                                  ? null
                                  : () {
                                      index == 11
                                          ? _deletePassword()
                                          : _selectPassword(
                                              keyPad[index]);
                                    },
                              child: Center(
                                child: index == 11
                                    ? SvgPicture.asset(AppIcons
                                        .passwordBackSpace)
                                    : AppText(
                                        keyPad[index],
                                        style: AppFontStyles
                                            .heading1
                                            .copyWith(
                                                color: AppColors
                                                    .grey900),
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Column selectedPassword(
      {required int index, required int passwordLength}) {
    return Column(
      children: [
        Container(
          height: 24.r,
          width: 24.r,
          decoration: BoxDecoration(
              border: Border.all(
                  color: AppColors.green500, width: 2),
              color: index < passwordLength
                  ? AppColors.green500
                  : null,
              shape: BoxShape.circle),
        ),
        Container(
          width: 40.w,
        )
      ],
    );
  }
}
