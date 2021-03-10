// Flutter imports:
import 'package:flutter/material.dart';

///Menu item data used in overflow menu (3 dots).
class YoYoPlayerOverflowMenuItem {
  ///Icon of menu item
  final IconData icon;

  ///Title of menu item
  final String title;

  ///Callback when item is clicked
  final Function() onClicked;

  YoYoPlayerOverflowMenuItem(this.icon, this.title, this.onClicked);
}
