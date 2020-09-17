import 'package:flutter/material.dart';

double calculateAspectRatio(BuildContext context, Size screenSize) {
  final width = screenSize.width;
  final height = screenSize.height;
  // return widget.playOptions.aspectRatio ?? controller.value.aspectRatio;
  return width > height ? width / height : height / width;
}
