import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('정말 로그아웃 하시겠습니까?'),
      content: SizedBox(
        width: 300, // 원하는 너비
        height: 150, // 원하는 높이
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("정말 로그아웃 하시겠습니까?"),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => context.pop(),
            child: const Text('취소')),
        TextButton(
            onPressed: () => context.pop(), child: Text('로그아웃'))
      ],
    );
  }
}
