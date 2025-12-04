import 'package:flutter/material.dart';

/// Lớp AppBorderRadius chứa các giá trị BorderRadius phổ biến với tên biến viết tắt
class AppBorderRadius {
  /// Border radius cực nhỏ - giá trị: BorderRadius.circular(2.0)
  static const BorderRadius xs = BorderRadius.all(Radius.circular(2.0));

  /// Border radius rất nhỏ - giá trị: BorderRadius.circular(4.0)
  static const BorderRadius xsm = BorderRadius.all(Radius.circular(4));

  /// Border radius nhỏ - giá trị: BorderRadius.circular(8.0)
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8));

  /// Border radius trung bình - giá trị: BorderRadius.circular(16.0)
  static const BorderRadius md = BorderRadius.all(Radius.circular(16));

  /// Border radius lớn - giá trị: BorderRadius.circular(24.0)
  static const BorderRadius lg = BorderRadius.all(Radius.circular(24));

  /// Border radius bottom lớn - giá trị: BorderRadius.circular(32.0)
  static const BorderRadius lgBottom =
      BorderRadius.vertical(bottom: Radius.circular(24.0));

  /// Border radius cực lớn - giá trị: BorderRadius.circular(32.0)
  static const BorderRadius xl = BorderRadius.all(Radius.circular(32.0));

  /// Border radius top cực lớn - giá trị: BorderRadius.circular(32.0)
  static const BorderRadius xlTop =
      BorderRadius.vertical(top: Radius.circular(32.0));

  /// Border radius bottom cực lớn - giá trị: BorderRadius.circular(32.0)
  static const BorderRadius xlBottom =
      BorderRadius.vertical(bottom: Radius.circular(32.0));
}
