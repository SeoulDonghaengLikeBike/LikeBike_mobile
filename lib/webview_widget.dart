import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart'; // 추가

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
  );

  bool _isWebViewReady = false;
  DateTime? _lastBackPressed;

  // 권한 요청 함수 추가
  Future<void> _requestPermissions() async {
    // Android 13 이상
    if (await Permission.photos.isGranted) {
      return;
    }
    
    Map<Permission, PermissionStatus> statuses = await [
      Permission.photos,
      Permission.storage,
      Permission.camera,
    ].request();

    debugPrint('Permission statuses: $statuses');
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions(); // 권한 요청
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isWebViewReady = true;
      });
    });
  }

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
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.green,
        body: _isWebViewReady
            ? InAppWebView(
                key: webViewKey,
                initialUrlRequest: URLRequest(
                  url: WebUri(
                    "https://port-next-likebike-front-mgl1nxa39d2d2d9a.sel3.cloudtype.app",
                  ),
                ),
                initialSettings: settings,
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  debugPrint("Page started loading: $url");
                },
                onPermissionRequest: (controller, request) async {
                  // 모든 권한 요청을 허용
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
                onLoadStop: (controller, url) async {
                  debugPrint("Page finished loading: $url");

                  // JavaScript 코드 간소화
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
                          // multiple 속성 제거하여 모든 이미지 접근 가능하게
                          input.removeAttribute('capture');
                          input.setAttribute('accept', 'image/*');
                        }
                      });
                    }
                    
                    setupFileInputs();
                    
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
                  ''',
                  );
                },
                onReceivedError: (controller, request, error) {
                  debugPrint("WebView error: ${error.description}");
                },
                onConsoleMessage: (controller, consoleMessage) {
                  debugPrint("Console: ${consoleMessage.message}");
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  var uri = navigationAction.request.url!;
                  debugPrint("Navigation to: $uri");
                  return NavigationActionPolicy.ALLOW;
                },
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}