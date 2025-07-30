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
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            // 메타 태그 추가 및 파일 입력 설정
            _controller.runJavaScript('''
              var meta = document.createElement('meta');
              meta.name = 'viewport';
              meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
              document.getElementsByTagName('head')[0].appendChild(meta);
              
              // 즉시 실행하여 기존 파일 입력 처리
              function setupFileInputs() {
                var fileInputs = document.querySelectorAll('input[type="file"]');
                fileInputs.forEach(function(input) {
                  if (input.accept && input.accept.includes('image')) {
                    input.setAttribute('capture', 'environment');
                    input.setAttribute('multiple', 'false');
                  }
                });
              }
              
              // 즉시 실행
              setupFileInputs();
              
              // DOM 변경 감지하여 새로운 파일 입력도 처리
              var observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                  if (mutation.type === 'childList') {
                    setupFileInputs();
                  }
                });
              });
              
              observer.observe(document.body, {
                childList: true,
                subtree: true
              });
              
              // DOMContentLoaded에서도 한 번 더 실행
              document.addEventListener('DOMContentLoaded', setupFileInputs);
            ''');

            setState(() {
              _isWebViewReady = true;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );

    _controller.loadRequest(Uri.parse('https://like-bike-front.vercel.app'));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final canGoBack = await _controller.canGoBack();

        if (canGoBack) {
          await _controller.goBack();
        } else {
          final now = DateTime.now();
          if (_lastBackPressed == null ||
              now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
            _lastBackPressed = now;

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('뒤로가기를 한 번 더 하면 앱이 종료됩니다.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        }
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 300) {
            _handleBackGesture();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.green,
          body: _isWebViewReady
              ? WebViewWidget(controller: _controller)
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Future<void> _handleBackGesture() async {
    final canGoBack = await _controller.canGoBack();

    if (canGoBack) {
      await _controller.goBack();
    } else {
      final now = DateTime.now();
      if (_lastBackPressed == null ||
          now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
        _lastBackPressed = now;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('뒤로가기를 한 번 더 하면 앱이 종료됩니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }
}
