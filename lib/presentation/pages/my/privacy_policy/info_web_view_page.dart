import 'package:dailymoji/core/styles/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InfoWebViewPage extends StatefulWidget {
  InfoWebViewPage({super.key, required this.title});
  final String title;

  @override
  State<InfoWebViewPage> createState() =>
      _InfoWebViewPageState();
}

class _InfoWebViewPageState extends State<InfoWebViewPage> {
  late final WebViewController _controller;
  late final String url;

  @override
  void initState() {
    super.initState();
    switch (widget.title) {
      case "공지사항":
        url =
            "https://www.notion.so/DailyMoji-27e3e951e08b80cebdbdfb10b8c35da4";
        break;
      case "이용 약관":
        url =
            "https://empty-judo-4e8.notion.site/DailyMoji-2793e951e08b80abb391d0a6cf9f7ca3";
        break;
      case "개인정보 처리방침":
        url =
            "https://www.notion.so/DailyMoji-27e069aa0a8280aabceded865e1f4473";
        break;
    }
    _webViewControl();
  }

  void _webViewControl() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse(url), // ← 여기에 노션 링크 넣기
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.white,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
