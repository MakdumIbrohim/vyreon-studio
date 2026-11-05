import 'package:flutter/material.dart';

enum DeviceScreenType {
  mobilePortrait,
  mobileLandscape,
  tablet,
  desktop,
}

class ResponsiveLayout {
  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  static double width(BuildContext context) => MediaQuery.of(context).size.width;
  static double height(BuildContext context) => MediaQuery.of(context).size.height;

  static DeviceScreenType getDeviceType(BuildContext context) {
    final w = width(context);
    final portrait = isPortrait(context);

    if (w >= 1024) {
      return DeviceScreenType.desktop;
    } else if (w >= 680) {
      return DeviceScreenType.tablet;
    } else if (portrait) {
      return DeviceScreenType.mobilePortrait;
    } else {
      return DeviceScreenType.mobileLandscape;
    }
  }

  /// Calculates optimal grid column count for project cards
  static int getDashboardColumns(BuildContext context) {
    final w = width(context);
    if (w < 460) {
      return 1;
    } else if (w < 720) {
      return 2;
    } else if (w < 1100) {
      return 3;
    } else if (w < 1440) {
      return 4;
    } else {
      return 5;
    }
  }

  /// Right inspector / wheel panel width for landscape & desktop
  static double getEditorPanelWidth(BuildContext context) {
    final w = width(context);
    if (w >= 1200) {
      return 320.0;
    } else if (w >= 900) {
      return 280.0;
    } else if (w >= 680) {
      return 240.0;
    } else {
      return (w * 0.35).clamp(200.0, 260.0);
    }
  }
}
