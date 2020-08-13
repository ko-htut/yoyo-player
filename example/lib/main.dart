import 'package:flutter/material.dart';
import 'package:yoyo_player/yoyo_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(
        body: Center(
          child: YoYoPlayer(
            aspectRatio: 16 / 9,
            url:
                // "",
                // "https://sfux-ext.sfux.info/hls/chapter/105/1588724110/1588724110.m3u8",
                "https://llvod.mxplay.com/video/6998aa0812ce347231c23033a98f31dc/11/hls/h264_baseline.m3u8",
            videoStyle: VideoStyle(),
            videoLoadingStyle: VideoLoadingStyle(
              loading: Center(
                child: Text("Loading video"),
              ),
            ),
            // subtitle:
            //     "https://eboxmovie.sgp1.digitaloceanspaces.com/mmmmtest.srt",
            subtitleStyle: SubtitleStyle(),
          ),
        ),
      ),
    );
  }
}
