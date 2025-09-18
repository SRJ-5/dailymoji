import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 16.r,
              backgroundImage: NetworkImage("https://picsum.photos/300/200"),
            ),
            SizedBox(width: 12.r),
            Text(
              "모지모지",
              style: TextStyle(
                fontSize: 14.sp,
                color: Color(0xFF333333),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.sp,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 12.w),
      ),
    );
  }
}
