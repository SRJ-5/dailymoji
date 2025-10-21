import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  bool _isLoading = true; // ← 로딩 상태 관리 변수

  @override
  void initState() {
    super.initState();
    switch (widget.title) {
      case "공지사항":
        url =
            "https://uttermost-eggplant-630.notion.site/DailyMoji-28085dd27ed380f38c8bc52a23ab5233?source=copy_link";
        break;
      case "이용 약관":
        url =
            "https://uttermost-eggplant-630.notion.site/DailyMoji-28085dd27ed380b9a68fe09898057360?source=copy_link";
        break;
      case "개인정보 처리방침":
        url =
            "https://uttermost-eggplant-630.notion.site/DailyMoji-28085dd27ed3805d828df9a1bc8152a8?source=copy_link";
        break;
      case "상담센터 연결":
        url = "https://findahelpline.com/ko-KR";
        break;
    }
    _webViewControl();
  }

  void _webViewControl() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: AppText(widget.title),
        backgroundColor: AppColors.white,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator()), // 로딩 스피너
            ),
        ],
      ),
    );
  }
}
