import 'package:dailymoji/presentation/widgets/bottom_bar.dart';
import 'package:flutter/material.dart';

class ReportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('ReportPage')),
      bottomNavigationBar: BottomBar(),
    );
  }
}
