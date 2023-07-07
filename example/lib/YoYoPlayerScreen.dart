import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:yoyo_player/yoyo_player.dart';

class YoYoPlayerScreen extends StatefulWidget {
  const YoYoPlayerScreen({super.key});

  @override
  State<YoYoPlayerScreen> createState() => _YoYoPlayerScreenState();
}

class _YoYoPlayerScreenState extends State<YoYoPlayerScreen> {
  bool fullscreen = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: fullscreen == false
          ? AppBar(
              backgroundColor: Colors.blue,
              title: Image(
                image: AssetImage('image/yoyo_logo.png'),
                fit: BoxFit.fitHeight,
                height: 50,
              ),
              centerTitle: true,
            )
          : null,
      body: Column(
        children: [
          YoYoPlayer(
            aspectRatio: 16 / 9,
            url:
                // "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
                // "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
                // "https://player.vimeo.com/external/440218055.m3u8?s=7ec886b4db9c3a52e0e7f5f917ba7287685ef67f&oauth2_token_id=1360367101",
                "https://sfux-ext.sfux.info/hls/chapter/105/1588724110/1588724110.m3u8",
            videoStyle: VideoStyle(),
            videoLoadingStyle: VideoLoadingStyle(
              loading: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image(
                      image: AssetImage('image/yoyo_logo.png'),
                      fit: BoxFit.fitHeight,
                      height: 50,
                    ),
                    Text("Loading video"),
                  ],
                ),
              ),
            ),
            onFullScreen: (t) {
              print(t);
              setState(() {
                fullscreen = t;
              });
            },
          ),
        ],
      ),
    );
  }
}