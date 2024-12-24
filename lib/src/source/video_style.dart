import 'package:flutter/material.dart';

/// Video Player Icon style
class VideoStyle {
  VideoStyle(
    this.backward, {
    this.play = const Icon(Icons.play_arrow),
    this.pause = const Icon(Icons.pause),
    this.fullscreen = const Icon(Icons.fullscreen),
    this.forward = const Icon(
      Icons.forward_10,
      color: Colors.white,
      size: 40,
    ),
    this.playedColor = Colors.green,
    this.qualitystyle = const TextStyle(
      color: Colors.white,
    ),
    this.qaShowStyle = const TextStyle(
      color: Colors.white,
    ),
  });

  final Widget play;
  final Widget pause;
  final Widget fullscreen;
  final Widget forward;
  final Widget backward;
  final Color playedColor;
  final TextStyle qualitystyle;
  final TextStyle qaShowStyle;
}
