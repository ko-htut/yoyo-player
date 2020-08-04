import 'package:flutter/material.dart';
import 'package:yoyo_player/yoyo_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Yo Yo Player'),
        ),
        body: YoYoPlayer(
          aspectRatio: 16 / 9,
          url:
              "https://player.vimeo.com/external/440218055.m3u8?s=7ec886b4db9c3a52e0e7f5f917ba7287685ef67f&oauth2_token_id=1360367101",
          videoIconStyle: VideoIconStyle(),
          videoLoadingStyle:
              VideoLoadingStyle(loading: Center(child: Text("Loading video"))),
        ),
      ),
    );
  }
}