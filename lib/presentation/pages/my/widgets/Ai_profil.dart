import 'package:flutter/material.dart';

class AiProfil extends StatelessWidget {
  const AiProfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      padding: EdgeInsets.all(15),
      child: Row(
        children: [
          CircleAvatar(radius: 55, backgroundColor: Colors.blue),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '솔루',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '성격 : 10 찐따',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Align(
            alignment: AlignmentGeometry.centerRight,
            child: Text(
              '편집',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
