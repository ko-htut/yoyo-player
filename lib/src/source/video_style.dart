import 'package:flutter/material.dart';

/// Video Player Icon style
class VideoStyle {
  VideoStyle({
    this.play = const Icon(Icons.play_arrow),
    this.pause = const Icon(Icons.pause),
    this.fullscreen = const Icon(Icons.fullscreen),
    this.forward = const Icon(Icons.skip_next),
    this.backward = const Icon(Icons.skip_previous),
    this.playedColor = Colors.amber,
    this.qualitystyle =
        const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    this.qashowstyle =
        const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
  });

  final Widget play;
  final Widget pause;
  final Widget fullscreen;
  final Widget forward;
  final Widget backward;
  final Color playedColor;
  final TextStyle qualitystyle;
  final TextStyle qashowstyle;
}
