// coverage:ignore-file
// ignore_for_file: use_full_hex_values_for_flutter_colors



import 'package:flutter/material.dart';

/// A list of custom color used in the application.
///
/// Will be ignored for test since all are static values and would not change.
// change.
abstract class ColorsValue {
  static Color appColor = const Color(0xFFFF5A00); // Updated to React Website Primary
  static Color primaryColor = appColor;
  static Color blackColor = const Color(0xFF000000);
  static Color whiteColor = const Color(0xFFFFFFFF);
  static Color appBg = whiteColor; // Alias for background
  static Color redColor = const Color(0xFFFF3B30); // Updated to React Website Red

  ///  Text Colors
  static Color txtBlackColor = const Color(0xff0B1727); // g1
  static Color txtG5Colors = const Color(0xff5E6E82); // g5
  static Color txtG7Color = const Color(0xff9DA9BB); // g7
  static Color txtG6Color = const Color(0xff748194); // g6
  static Color txtGreenColor = const Color(0xff12724A);
  static Color txtRedColor = const Color(0xffFF3B30);

  /// Container colors
  /// CB ----> Container background
  static Color bulycolorsCB = const Color(0xffEDF2F9); // l3
  static Color yellocolorsCB = const Color(0xffFFF2ED); // Updated to l1 from Tailwind
  static Color yellocolors2CB = const Color(0xffFFF2ED); 
  static Color l4CB = const Color(0xffF9FAFD); // l4
  static Color borderColors = const Color(0xffD8E2EF); // l2
  static Color coupanBG = const Color(0xffF7F7FC); 
}
