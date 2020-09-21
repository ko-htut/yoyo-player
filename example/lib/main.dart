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
                "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
                // "https://player.vimeo.com/external/440218055.m3u8?s=7ec886b4db9c3a52e0e7f5f917ba7287685ef67f&oauth2_token_id=1360367101",
                // "https://sfux-ext.sfux.info/hls/chapter/105/1588724110/1588724110.m3u8",
            videoStyle: VideoStyle(),
            videoLoadingStyle: VideoLoadingStyle(
              loading: Center(
                child: Text("Loading video"),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
