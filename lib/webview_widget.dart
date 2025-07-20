import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MyWebView extends StatefulWidget {
  const MyWebView({super.key});

  @override
  State<MyWebView> createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  late final WebViewController _controller;
  bool _isWebViewReady = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // 페이지 로딩 진행 상황을 확인할 수 있습니다.
          },
          onPageStarted: (String url) {
            // 페이지 로딩 시작 시 호출됩니다.
          },
          onPageFinished: (String url) {
            // 페이지 로딩 완료 시 호출됩니다.
            setState(() {
              _isWebViewReady = true; // 로딩 완료 시 상태 업데이트
            });
          },
          onWebResourceError: (WebResourceError error) {
            // 웹 리소스 로딩 중 에러 발생 시 호출됩니다.
          },
          onNavigationRequest: (NavigationRequest request) {
            // 페이지 이동 요청 시 호출됩니다.
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://like-bike-front.vercel.app'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(title: const Text('LikeBike')),
      body:
          _isWebViewReady // 웹뷰가 준비되었을 때만 WebViewWidget 표시
          ? WebViewWidget(controller: _controller)
          : Center(
              child: CircularProgressIndicator(), // 로딩 중 인디케이터 표시
            ),
    );
  }
}
