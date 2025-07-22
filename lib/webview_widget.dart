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
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
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
            // 모바일 최적화를 위한 뷰포트 설정
            _controller.runJavaScript('''
              var meta = document.createElement('meta');
              meta.name = 'viewport';
              meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
              document.getElementsByTagName('head')[0].appendChild(meta);
              
              // 파일 업로드 지원을 위한 설정
              document.addEventListener('DOMContentLoaded', function() {
                var fileInputs = document.querySelectorAll('input[type="file"]');
                fileInputs.forEach(function(input) {
                  // 모바일에서 카메라 직접 접근을 위한 속성 추가
                  if (input.accept && input.accept.includes('image')) {
                    input.setAttribute('capture', 'environment');
                  }
                });
              });
            ''');

            setState(() {
              _isWebViewReady = true; // 로딩 완료 시 상태 업데이트
            });
          },
          onWebResourceError: (WebResourceError error) {
            // 웹 리소스 로딩 중 에러 발생 시 호출됩니다.
            print('WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            // 페이지 이동 요청 시 호출됩니다.
            return NavigationDecision.navigate;
          },
        ),
      );

    _controller.loadRequest(Uri.parse('https://like-bike-front.vercel.app'));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 기본 뒤로가기 동작을 비활성화
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // WebView에서 뒤로갈 페이지가 있는지 확인
        final canGoBack = await _controller.canGoBack();

        if (canGoBack) {
          // WebView 내에서 뒤로가기 실행
          await _controller.goBack();
        } else {
          // 뒤로갈 페이지가 없으면 더블 탭으로 앱 종료
          final now = DateTime.now();
          if (_lastBackPressed == null ||
              now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
            _lastBackPressed = now;

            // 토스트 메시지 대신 스낵바로 안내
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('뒤로가기 버튼을 한 번 더 누르면 앱이 종료됩니다.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            // 2초 내에 다시 뒤로가기를 누르면 앱 종료
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.green,
        body:
            _isWebViewReady // 웹뷰가 준비되었을 때만 WebViewWidget 표시
            ? WebViewWidget(controller: _controller)
            : const Center(
                child: CircularProgressIndicator(), // 로딩 중 인디케이터 표시
              ),
      ),
    );
  }
}
