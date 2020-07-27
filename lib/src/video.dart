import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class YoYoPlayer extends StatefulWidget {
  /// yoyo_player is a video player that allows you to select HLS video streaming by selecting the quality
  ///
  final String url;
  YoYoPlayer(this.url, {Key key}) : super(key: key);

  @override
  _YoYoPlayerState createState() => _YoYoPlayerState();
}

class _YoYoPlayerState extends State<YoYoPlayer> {
  VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    initPlayer();
  }

  void initPlayer() {}

  void m3u8video(){

  }

  

  @override
  Widget build(BuildContext context) {
    return VideoPlayer(controller);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
