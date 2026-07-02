import 'package:flutter/widgets.dart';

/// 화면 너비 기준값. 모바일 앱이 기본이지만 웹/데스크톱 브라우저에서
/// 열었을 때도 레이아웃이 깨지지 않도록 화면별로 이 값을 참조한다.
class Breakpoints {
  Breakpoints._();

  static const double mobile = 600;
  static const double desktop = 1024;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isMobile => screenWidth < Breakpoints.mobile;

  bool get isDesktop => screenWidth >= Breakpoints.desktop;
}
