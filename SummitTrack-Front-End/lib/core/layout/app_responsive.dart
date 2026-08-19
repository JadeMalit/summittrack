import 'package:flutter/material.dart';

class AppResponsive {
  AppResponsive._();

  static const double compactPhoneWidth = 360;
  static const double largePhoneWidth = 430;
  static const double maxContentWidth = 600;

  static const double pagePaddingCompact = 16;
  static const double pagePadding = 20;

  static const double floatingNavHeight = 56;
  static const double floatingNavBottomMargin = 10;
  static const double floatingNavTopGap = 18;

  static bool isCompactWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width < compactPhoneWidth;
  }

  static double horizontalPagePadding(BuildContext context) {
    return isCompactWidth(context) ? pagePaddingCompact : pagePadding;
  }

  static double floatingNavClearance(
    BuildContext context, {
    double extraGap = floatingNavTopGap,
  }) {
    return MediaQuery.paddingOf(context).bottom +
        floatingNavHeight +
        floatingNavBottomMargin +
        extraGap;
  }

  static double bottomDockClearance(
    BuildContext context, {
    required double dockHeight,
    double bottomMargin = pagePaddingCompact,
    double extraGap = floatingNavTopGap,
  }) {
    return MediaQuery.paddingOf(context).bottom +
        dockHeight +
        bottomMargin +
        extraGap;
  }

  static EdgeInsets scrollPaddingWithFloatingNav(
    BuildContext context, {
    double top = 0,
    double horizontal = pagePadding,
    double extraBottomGap = floatingNavTopGap,
  }) {
    return EdgeInsets.fromLTRB(
      horizontal,
      top,
      horizontal,
      floatingNavClearance(context, extraGap: extraBottomGap),
    );
  }

  static double clampedWidthHeight(
    double width, {
    required double ratio,
    required double min,
    required double max,
  }) {
    return (width * ratio).clamp(min, max).toDouble();
  }

  static double clampedScreenHeight(
    BuildContext context, {
    required double ratio,
    required double min,
    required double max,
  }) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final availableHeight = size.height - padding.vertical - 24;
    final effectiveMax = availableHeight < max ? availableHeight : max;
    if (effectiveMax <= 0) {
      return 0;
    }

    final target = (size.height * ratio).clamp(min, max).toDouble();
    return target > effectiveMax ? effectiveMax : target;
  }
}
