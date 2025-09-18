import 'package:flutter/material.dart';

class DiagnosticTestBox extends StatelessWidget {
  const DiagnosticTestBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.grey, width: 1),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          '진단검사',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Divider(height: 1, color: Colors.grey),
          ListTile(
            title: Text('우울 진단검사'),
            visualDensity: VisualDensity(vertical: -2),
          ),
          Divider(height: 1, color: Colors.grey),
          ListTile(
            title: Text('스트레스 진단검사'),
            visualDensity: VisualDensity(vertical: -2),
          ),
          Divider(height: 1, color: Colors.grey),
          ListTile(
            title: Text('불안 진단검사'),
            visualDensity: VisualDensity(vertical: -2),
          ),
          Divider(height: 1, color: Colors.grey),
          ListTile(
            title: Text('번아웃 진단검사'),
            visualDensity: VisualDensity(vertical: -2),
          ),
          Divider(height: 1, color: Colors.grey),
          ListTile(
            title: Text('자존감 진단검사'),
            visualDensity: VisualDensity(vertical: -4),
          ),
          Divider(height: 1, color: Colors.grey),
        ],
      ),
    );
  }
}
