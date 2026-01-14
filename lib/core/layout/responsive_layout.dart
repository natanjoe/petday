import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;

  // Breakpoint centralizado
  static const double desktopBreakpoint = 1024;

  const ResponsiveLayout({
    required this.mobile,
    required this.desktop,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < desktopBreakpoint) {
      return mobile;
    }
    return desktop;
  }
}
