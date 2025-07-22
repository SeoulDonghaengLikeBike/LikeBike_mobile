import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:likebike/webview_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: Builder(
              builder: (safeContext) {
                // SafeArea가 적용된 후의 실제 사용 가능한 화면 크기
                final safeAreaSize = MediaQuery.of(safeContext).size;

                return ScreenUtilInit(
                  designSize: safeAreaSize,
                  minTextAdapt: true,
                  splitScreenMode: true,
                  builder: (context, child) => const MyWebView(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
