import 'package:dailymoji/core/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse(
            "https://www.notion.so/DailyMoji-27e069aa0a8280aabceded865e1f4473"), // ← 여기에 노션 링크 넣기
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("개인정보 처리방침"),
        backgroundColor: AppColors.white,
        centerTitle: true,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
