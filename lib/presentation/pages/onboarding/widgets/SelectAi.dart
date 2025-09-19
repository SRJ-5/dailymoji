import 'package:flutter/material.dart';

class SelectAi extends StatelessWidget {
  const SelectAi({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            '도우미 모지 캐릭터를 골라주세요!',
            style: TextStyle(fontSize: 40),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  child: Image.asset(
                      'assets/images/cado_profile.png'),
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
