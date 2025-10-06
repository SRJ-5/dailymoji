import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';

class SelectAi extends StatelessWidget {
  const SelectAi({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          AppText(
            '도우미 모지 캐릭터를 골라주세요!',
            style: TextStyle(fontSize: 40),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  child: Image.asset(AppImages.cadoProfile),
                ),
                SizedBox(
                  width: 20,
                ),
                CircleAvatar(
                  radius: 60,
                  child: Icon(
                    Icons.help_outline_outlined,
                    size: 100,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
