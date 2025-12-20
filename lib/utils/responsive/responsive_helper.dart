import 'package:flutter/material.dart';

class ResponsiveHelper {
  /// Tính toán kích thước responsive dựa trên phần trăm của màn hình
  static double getResponsiveHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }

  static double getResponsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  /// Tính toán kích thước icon responsive
  static double getResponsiveIconSize(BuildContext context, double percentage) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * percentage;
  }

  /// Tính toán font size responsive
  static double getResponsiveFontSize(BuildContext context, double percentage) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * percentage;
  }

  /// Tính toán padding responsive
  static EdgeInsets getResponsivePadding(BuildContext context, {
    double? horizontalPercentage,
    double? verticalPercentage,
    double? allPercentage,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (allPercentage != null) {
      return EdgeInsets.all(screenWidth * allPercentage);
    }

    return EdgeInsets.symmetric(
      horizontal: horizontalPercentage != null ? screenWidth * horizontalPercentage : 0,
      vertical: verticalPercentage != null ? screenHeight * verticalPercentage : 0,
    );
  }

  /// Tính toán margin responsive
  static EdgeInsets getResponsiveMargin(BuildContext context, {
    double? horizontalPercentage,
    double? verticalPercentage,
    double? allPercentage,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (allPercentage != null) {
      return EdgeInsets.all(screenWidth * allPercentage);
    }

    return EdgeInsets.symmetric(
      horizontal: horizontalPercentage != null ? screenWidth * horizontalPercentage : 0,
      vertical: verticalPercentage != null ? screenHeight * verticalPercentage : 0,
    );
  }

  /// Tính toán border radius responsive
  static double getResponsiveBorderRadius(BuildContext context, double percentage) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * percentage;
  }

  /// Kiểm tra xem có phải màn hình nhỏ không
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Kiểm tra xem có phải màn hình trung bình không
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  /// Kiểm tra xem có phải màn hình lớn không
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  /// Lấy breakpoint hiện tại
  static ResponsiveBreakpoint getBreakpoint(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return ResponsiveBreakpoint.small;
    if (width < 1200) return ResponsiveBreakpoint.medium;
    return ResponsiveBreakpoint.large;
  }
}

enum ResponsiveBreakpoint {
  small,
  medium,
  large,
}




