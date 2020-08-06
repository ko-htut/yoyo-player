import 'package:flutter/material.dart';
import 'package:yoyo_player/yoyo_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(
        body: YoYoPlayer(
          aspectRatio: 16 / 9,
          url: "",
          videoIconStyle: VideoIconStyle(),
          videoLoadingStyle: VideoLoadingStyle(
            loading: Center(
              child: Text("Loading video"),
            ),
          ),
          subtitle: "",
          subtitleStyle: SubtitleStyle(),
        ),
      ),
    );
  }
}
