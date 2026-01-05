import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BuildSection extends StatelessWidget {
  final String? title;
  final List<String> items;
  final List<VoidCallback> onTapList;
  final Icon? icon;
  final Widget? widget;
  final List<Widget?>? widgets;
  final List<Color?>? textColors;
  BuildSection({
    super.key,
    required this.title,
    required this.items,
    required this.onTapList,
    this.icon,
    this.widget,
    this.widgets,
    this.textColors,
  });

  @override
  Widget build(BuildContext context) {
    bool isTitle = false;
    if (title == null) {
      isTitle = true;
    }

    return Container(
      padding: EdgeInsets.only(
          top: isTitle ? 0 : 16.h, left: 16.w, right: 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.grey100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isTitle
              ? SizedBox.shrink()
              : AppText(
                  title!,
                  style: AppFontStyles.bodyBold14.copyWith(
                    color: AppColors.grey900,
                  ),
                ),
          ...List.generate(
            items.length * 2 - 1,
            (index) => index.isEven
                ? GestureDetector(
                    onTap: (widgets != null &&
                                index ~/ 2 < widgets!.length &&
                                widgets![index ~/ 2] != null) ||
                            widget != null
                        ? null
                        : onTapList[index ~/ 2],
                    child: buildSettingItem(
                      title: items[index ~/ 2],
                      icon: icon,
                      widget: widgets != null &&
                              index ~/ 2 < widgets!.length &&
                              widgets![index ~/ 2] != null
                          ? widgets![index ~/ 2]
                          : widget,
                      textColor: textColors != null &&
                              index ~/ 2 < textColors!.length &&
                              textColors![index ~/ 2] != null
                          ? textColors![index ~/ 2]
                          : null,
                    ),
                  )
                : Divider(
                    height: 1.h,
                    color: AppColors.grey100,
                  ),
          ),
        ],
      ),
    );
  }
}

Container buildSettingItem({
  required String title,
  Icon? icon,
  Widget? widget,
  Color? textColor,
}) {
  return Container(
    color: AppColors.white,
    height: 48.h,
    child: Row(
      children: [
        AppText(
          title,
          style: textColor != null
              ? AppFontStyles.bodyRegular16
                  .copyWith(color: textColor)
              : widget == null
                  ? AppFontStyles.bodyRegular16
                      .copyWith(color: AppColors.grey300)
                  : AppFontStyles.bodyBold16.copyWith(
                      color: AppColors.grey900,
                    ),
        ),
        Spacer(),
        widget ?? Container(),
        widget != null
            ? SizedBox.shrink()
            : icon ??
                Icon(
                  Icons.chevron_right,
                  color: textColor ?? AppColors.grey300,
                  size: 24.sp,
                ),
      ],
    ),
  );
}

class Toggle extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  const Toggle({
    super.key,
    this.initialValue = false,
    this.onChanged,
  });

  @override
  State<Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<Toggle> {
  late bool _isOn;

  @override
  void initState() {
    super.initState();
    _isOn = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant Toggle oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 수정 전: if (oldWidget.initialValue != widget.initialValue)
    // 🚨 수정 후: 부모가 주는 값(widget.initialValue)이 현재 내 상태(_isOn)와 다르면 동기화
    if (widget.initialValue != _isOn) {
      setState(() {
        _isOn = widget.initialValue;
        // 이렇게 하면 _isOn이 true -> false로 바뀌면서
        // AnimatedPositioned가 작동해 스르륵 돌아갑니다.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 위아래 중앙 위치: (전체 높이 - 원의 높이) / 2
    final double centerVertical = (30.h - 24.r) / 2;
    // 왼쪽 위치: 4.w
    final double leftPosition = 5.w;
    // 오른쪽 위치: 전체 너비 - 원의 너비 - 4.w
    final double rightPosition = 60.w - 24.r - 5.w;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isOn = !_isOn;
        });
        widget.onChanged?.call(_isOn);
      },
      child: Container(
        width: 60.w,
        height: 30.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50.r),
          color: _isOn ? AppColors.green500 : AppColors.grey100,
          border: Border.all(
              color: AppColors.grey200, strokeAlign: 1),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              left: _isOn ? rightPosition : leftPosition,
              top: centerVertical,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                width: 24.r,
                height: 24.r,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
