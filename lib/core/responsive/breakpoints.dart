import 'package:flutter/widgets.dart';

/// 화면 너비 기준값.
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
