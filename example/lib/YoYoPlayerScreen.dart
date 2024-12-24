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
      appBar: MediaQuery.of(context).orientation != Orientation.landscape
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
          Expanded(
            child: Center(
              child: YoYoPlayer(
                aspectRatio: 16 / 9,
                url: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
                authToken: "authtoken",
                contentID: "contentID",
                contentViewId: "contentViewId",
                domianUrl: "domianUrl",
                isVideoProgressenable: 1,
                timeRecordVideoProgress: 2,

                // "https://vz-fd93b4ad-1aa.b-cdn.net/64a045f8-8935-4369-b83f-06f043ddf6b1/playlist.m3u8",
                // "https://vz-7b6a17bc-fc1.b-cdn.net/43babd4b-eaed-4a93-baa9-2c2ebf091fb6/playlist.m3u8?v=1689179659",
                // "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
                // "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
                // "https://player.vimeo.com/external/440218055.m3u8?s=7ec886b4db9c3a52e0e7f5f917ba7287685ef67f&oauth2_token_id=1360367101",
                // "https://vz-d841190e-3d4.b-cdn.net/f0afa00b-459a-47ab-9d28-9952b8976e9d/playlist.m3u8?withoutwebview",
                videoStyle: VideoStyle(
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(3.14),
                    child: Icon(
                      Icons.forward_10,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
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
            ),
          ),
        ],
      ),
    );
  }
}
