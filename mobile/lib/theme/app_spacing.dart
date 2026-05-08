import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double screen = 16;
  static const double screenCompact = 12;
  static const double card = 16;
  static const double gap = 12;
  static const double gapSm = 10;

  static const double compactBreakpoint = 640;
  static const double desktopContentMaxWidth = 760;

  static const EdgeInsets screenPadding = EdgeInsets.all(screen);
  static const EdgeInsets cardPadding = EdgeInsets.all(card);

  static bool compactLayout(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  static EdgeInsets screenPaddingFor(BuildContext context) =>
      compactLayout(context)
          ? const EdgeInsets.fromLTRB(screenCompact, screen, screenCompact, screen)
          : screenPadding;
}

abstract final class AppColors {
  static const Color prescriptionFill = Color(0xFFFFF59D);
  static const Color prescriptionBorder = Color(0xFFFFEB3B);
  static const Color prescriptionOnSurface = Color(0xFF4E342E);
}
