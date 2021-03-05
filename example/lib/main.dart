import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yoyo_player/yoyo_player.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late VideoPlayerController _videoPlayerController;
  late YoYoController _yoyoController;
  double _aspectRatio = 16 / 9;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.network(
        // "http://103.121.224.26/img/uploads/5fcb4e15694ea-Titanic%202%20Full%20Movie%20-%20Hollywood%20Full%20Movie%202020%20-%20Full%20Movies%20in%20English%20%F0%9D%90%85%F0%9D%90%AE%F0%9D%90%A5%F0%9D%90%A5%20%F0%9D%90%87%F0%9D%90%83%201080.m3u8");
        // "http://103.121.224.26/img/uploads/5fd8e168a9988-Titanic.m3u8");
        "https://sfux-ext.sfux.info/hls/chapter/105/1588724110/1588724110.m3u8");

    _yoyoController = YoYoController(
      cupertinoProgressColors: new YoYoProgressColors(
        playedColor: Color.fromARGB(255, 255, 219, 79),
        handleColor: Color.fromARGB(255, 255, 219, 79),
        backgroundColor: Colors.grey,
        bufferedColor: Colors.lightGreen,
      ),
      allowedScreenSleep: false,
      allowFullScreen: true,
      fullScreenByDefault: false,
      errorBuilder: (context, errorMessage) {
        return Center(child: Text('ERROR'));
      },
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
      videoPlayerController: _videoPlayerController,
      aspectRatio: _aspectRatio,
      autoInitialize: true,
      autoPlay: true,
      showControls: true,
      placeholder: new Container(
        color: Colors.black,
      ),
    );
    _yoyoController.addListener(() {
      if (_yoyoController.isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
      }
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _yoyoController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Image(
            image: AssetImage('image/yoyo_logo.png'),
            fit: BoxFit.fitHeight,
            height: 50,
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            YoYoPlayer(
              // aspectRatio: 16 / 9,
              // url:
              //     // "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
              //     // "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8",
              //     // "https://player.vimeo.com/external/440218055.m3u8?s=7ec886b4db9c3a52e0e7f5f917ba7287685ef67f&oauth2_token_id=1360367101",
              //     "https://sfux-ext.sfux.info/hls/chapter/105/1588724110/1588724110.m3u8",
              // videoStyle: VideoStyle(),
              // videoLoadingStyle: VideoLoadingStyle(
              //   loading: Center(
              //     child: Column(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       crossAxisAlignment: CrossAxisAlignment.center,
              //       children: [
              //         Image(
              //           image: AssetImage('image/yoyo_logo.png'),
              //           fit: BoxFit.fitHeight,
              //           height: 50,
              //         ),
              //         Text("Loading video"),
              //       ],
              //     ),
              //   ),
              // ),
              // onFullScreen: (t) {
              //   setState(() {
              //     fullscreen = t;
              //   });
              controller: _yoyoController,
            ),
          ],
        ),
      ),
    );
  }
}
