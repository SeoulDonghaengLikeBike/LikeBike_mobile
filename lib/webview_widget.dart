import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MyWebView extends StatefulWidget {
  const MyWebView({super.key});

  @override
  State<MyWebView> createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
    useShouldOverrideUrlLoading: true,
    useOnLoadResource: true,
    allowFileAccess: true,
    allowFileAccessFromFileURLs: true,
    allowUniversalAccessFromFileURLs: true,
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    clearCache: false,
    cacheEnabled: true,
    supportZoom: false,
    userAgent:
        "Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
  );

  bool _isWebViewReady = false;
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final canGoBack = await webViewController?.canGoBack() ?? false;

        if (canGoBack) {
          await webViewController?.goBack();
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
              ? InAppWebView(
                  key: webViewKey,
                  initialUrlRequest: URLRequest(
                    url: WebUri("https://like-bike-front.vercel.app"),
                  ),
                  initialSettings: settings,
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                  onLoadStart: (controller, url) {
                    debugPrint("Page started loading: $url");
                  },
                  onPermissionRequest: (controller, request) async {
                    // 카메라, 마이크 등의 권한 요청을 자동으로 허용
                    return PermissionResponse(
                      resources: request.resources,
                      action: PermissionResponseAction.GRANT,
                    );
                  },
                  onLoadStop: (controller, url) async {
                    debugPrint("Page finished loading: $url");

                    // 파일 입력 설정을 위한 JavaScript 실행
                    await controller.evaluateJavascript(
                      source: '''
                      var meta = document.createElement('meta');
                      meta.name = 'viewport';
                      meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                      document.getElementsByTagName('head')[0].appendChild(meta);
                      
                      function setupFileInputs() {
                        var fileInputs = document.querySelectorAll('input[type="file"]');
                        console.log('Found file inputs:', fileInputs.length);
                        
                        fileInputs.forEach(function(input, index) {
                          console.log('Setting up file input', index, input);
                          
                          if (input.accept && input.accept.includes('image')) {
                            input.setAttribute('capture', 'environment');
                            input.setAttribute('multiple', 'false');
                            input.setAttribute('accept', 'image/*');
                            
                            // 파일 선택 이벤트 리스너 추가
                            input.addEventListener('click', function(e) {
                              console.log('File input clicked');
                            });
                          }
                        });
                      }
                      
                      // 즉시 실행
                      setupFileInputs();
                      
                      // DOM 변경 감지
                      var observer = new MutationObserver(function(mutations) {
                        var shouldSetup = false;
                        mutations.forEach(function(mutation) {
                          if (mutation.type === 'childList') {
                            mutation.addedNodes.forEach(function(node) {
                              if (node.nodeType === 1) {
                                if (node.tagName === 'INPUT' || (node.querySelector && node.querySelector('input[type="file"]'))) {
                                  shouldSetup = true;
                                }
                              }
                            });
                          }
                        });
                        if (shouldSetup) {
                          setTimeout(setupFileInputs, 100);
                        }
                      });
                      
                      observer.observe(document.body, {
                        childList: true,
                        subtree: true
                      });
                      
                      // DOMContentLoaded에서도 실행
                      document.addEventListener('DOMContentLoaded', function() {
                        setTimeout(setupFileInputs, 500);
                      });
                      
                      // 페이지 로드 완료 후에도 한 번 더
                      setTimeout(setupFileInputs, 1000);
                    ''',
                    );
                  },
                  onReceivedError: (controller, request, error) {
                    debugPrint("WebView error: ${error.description}");
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    debugPrint("Console: ${consoleMessage.message}");
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                        var uri = navigationAction.request.url!;
                        debugPrint("Navigation to: $uri");

                        // 모든 URL 허용 (OAuth 포함)
                        return NavigationActionPolicy.ALLOW;
                      },
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isWebViewReady = true;
      });
    });
  }

  Future<void> _handleBackGesture() async {
    final canGoBack = await webViewController?.canGoBack() ?? false;

    if (canGoBack) {
      await webViewController?.goBack();
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
