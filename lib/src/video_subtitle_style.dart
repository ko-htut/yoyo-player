import 'package:flutter/material.dart';

class SubtitleStyle {
  SubtitleStyle({
    this.fontweight = FontWeight.normal,
    this.colors = Colors.white,
    this.background = Colors.black38,
    this.fontSize = 15,
  });

  final FontWeight fontweight;
  final Color colors;
  final Color background;
  final double fontSize;
}
