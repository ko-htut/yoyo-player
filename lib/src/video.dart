import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orientation/orientation.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

import '../yoyo_player.dart';
import 'model/audio.dart';
import 'model/m3u8.dart';
import 'model/subtitle.dart';
import 'widget/top_chip.dart';

typedef VideoCallback<T> = void Function(T t);

class YoYoPlayer extends StatefulWidget {
  ///Video source
  final String url;

  /// Video Player  style
  final VideoStyle videoStyle;

  /// Video Loading Style
  final VideoLoadingStyle videoLoadingStyle;

  /// Video AspectRaitio [aspectRatio : 16 / 9 ]
  final double aspectRatio;

  /// video state fullscreen
  final VideoCallback<bool> onfullscreen;

  /// video Type
  final VideoCallback<String> onpeningvideo;

  YoYoPlayer({
    Key key,
    @required this.url,
    @required this.aspectRatio,
    this.videoStyle,
    this.videoLoadingStyle,
    this.onfullscreen,
    this.onpeningvideo,
  }) : super(key: key);

  @override
  _YoYoPlayerState createState() => _YoYoPlayerState();
}

class _YoYoPlayerState extends State<YoYoPlayer>
    with SingleTickerProviderStateMixin {
  //vieo play type (hls,mp4,mkv,offline)
  String _playtype;
  // Animation Controller
  AnimationController controlBarAnimationController;
  // Video Top Bar Animation
  Animation<double> controlTopBarAnimation;
  // Video Bottom Bar Animation
  Animation<double> controlBottomBarAnimation;
  // Vieo Player Controller
  VideoPlayerController controller;
  // Video init error defult :false
  bool hasInitError = false;
  // Video Total Time duration
  String videoDuration;
  // Viedo Seed to
  String videoSeek;

  Duration duration;
  Duration duration2;
  double videoSeekSecond;
  double videoDurationSecond;
  //m3u8 data video list
  List<M3U8pass> m3u8List = List();
  // m3u8 audio list
  List<AUDIO> audioList = List();
  String m3u8Content;
  String subtitleContent;

  bool m3u8show = false;
  bool fullscreen = false;
  bool showMeau = false;
  bool showSubtitles = false;
  bool offline;
  String m3u8quality = "Auto";
  Timer showTime;
  bool sublistener = false;
  Subtitle subtitle;
  Size get screenSize => MediaQuery.of(context).size;
  //
  @override
  void initState() {
    // TODO: implement initState
    urlcheck(widget.url);
    super.initState();

    /// Control bar animation
    controlBarAnimationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    controlTopBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);
    controlBottomBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);
    var widgetsBinding = WidgetsBinding.instance;

    widgetsBinding.addPostFrameCallback((callback) {
      widgetsBinding.addPersistentFrameCallback((callback) {
        if (context == null) return;
        var orientation = MediaQuery.of(context).orientation;
        bool _fullscreen;
        if (orientation == Orientation.landscape) {
          //Horizontal screen
          _fullscreen = true;
          SystemChrome.setEnabledSystemUIOverlays([]);
        } else if (orientation == Orientation.portrait) {
          _fullscreen = false;
          SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
        }
        if (_fullscreen != fullscreen) {
          setState(() {
            fullscreen = !fullscreen;
            _navigateLocally(context);
            if (widget.onfullscreen != null) {
              widget.onfullscreen(fullscreen);
            }
          });
        }
        //
        widgetsBinding.scheduleFrame();
      });
    });
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    Screen.keepOn(true);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoChildrens = <Widget>[
      GestureDetector(
        onTap: () {
          // toggleControls();
        },
        onDoubleTap: () {
          // togglePlay();
        },
        child: ClipRect(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Center(
                child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            )),
          ),
        ),
      ),
    ];
    videoChildrens.addAll(videoBuiltInChildrens());
    return AspectRatio(
      aspectRatio:
          fullscreen ? _calculateAspectRatio(context) : widget.aspectRatio,
      child: controller.value.initialized
          ? Stack(children: videoChildrens)
          : widget.videoLoadingStyle.loading,
    );
  }

  /// Vieo Player ActionBar
  Widget actionBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: 40,
        width: double.infinity,
        // color: Colors.yellow,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            topchip(Text("Myanmar"), () {
              // subtitle function
            }),
            Container(
              width: 5,
            ),
            topchip(Text("1080p"), () {
              // quality function
            }),
            Container(
              width: 5,
            ),
            topchip(Icon(Icons.fullscreen), () {
              // full screen function
            }),
            Container(
              width: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget bottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 40,
        child: Padding(
          padding: EdgeInsets.all(0.0),
          child: Stack(
            children: [
              Column(
                children: [
                  VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                        playedColor: widget.videoStyle.playedColor),
                    padding: EdgeInsets.only(left: 5.0, right: 5),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 5.0, right: 5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$videoSeek',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '$videoDuration',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.skip_previous),
                      Icon(Icons.play_circle_outline),
                      Icon(Icons.skip_next),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget subtitleShow() {
    return Text("subtitle");
  }

  List<Widget> videoBuiltInChildrens() {
    return [
      actionBar(),
      subtitleShow(),
      bottomBar(),
    ];
  }

  void urlcheck(String url) {
    final netRegx = new RegExp(r'^(http|https):\/\/([\w.]+\/?)\S*');
    final isNetwork = netRegx.hasMatch(url);
    if (isNetwork) {
      setState(() {
        offline = false;
      });
      if (url.endsWith(".mkv")) {
        if (widget.onpeningvideo != null) {
          widget.onpeningvideo("MKV");
        }
        videoControllSetup(url);
      } else if (url.endsWith(".mp4")) {
        if (widget.onpeningvideo != null) {
          widget.onpeningvideo("MP4");
        }
        videoControllSetup(url);
      } else if (url.endsWith(".m3u8")) {
        if (widget.onpeningvideo != null) {
          widget.onpeningvideo("M3U8");
        }
        videoControllSetup(url);
        getm3u8(url);
      } else {
        videoControllSetup(url);
        getm3u8(url);
      }
      print("online");
      print("online $offline");
    } else {
      setState(() {
        offline = true;
        print("offline $offline");
      });
      videoControllSetup(url);
    }
  }

// M3U8 Data Setup
  void getm3u8(String video) {
    if (m3u8List.length > 0) {
      print("${m3u8List.length} : data start clean");
      // m3u8clean();
    }
    print("fet new data form $video data start");
    // m3u8video(video);
  }

// Video controller
  void videoControllSetup(String url) {
    videoInit(url);
    controller.addListener(listener);
    controller.play();
  }

// video Listener
  void listener() async {
    if (controller.value.initialized && controller.value.isPlaying) {
      if (!await Wakelock.isEnabled) {
        await Wakelock.enable();
      }
      setState(() {
        videoDuration = convertDurationToString(controller.value.duration);
        videoSeek = convertDurationToString(controller.value.position);
        videoSeekSecond = controller.value.position.inSeconds.toDouble();
        videoDurationSecond = controller.value.duration.inSeconds.toDouble();
      });
    } else {
      if (await Wakelock.isEnabled) {
        await Wakelock.disable();
        setState(() {});
      }
    }
    if (sublistener != false) {
      // _subtitleWatcher(controller);
    }
  }

  void videoInit(String url) {
    if (offline == false) {
      print("play init url $url offline $offline");
      controller =
          VideoPlayerController.network(url, formatHint: VideoFormat.hls)
            ..initialize()
                .then((_) => setState(() => hasInitError = false))
                .catchError((e) => setState(() => hasInitError = true));
    } else {
      print("play init url $url offline $offline");
      controller = VideoPlayerController.file(File(url))
        ..initialize()
            .then((value) => setState(() => hasInitError = false))
            .catchError((e) => setState(() => hasInitError = true));
    }
  }

  String convertDurationToString(Duration duration) {
    var minutes = duration.inMinutes.toString();
    if (minutes.length == 1) {
      minutes = '0' + minutes;
    }
    var seconds = (duration.inSeconds % 60).toString();
    if (seconds.length == 1) {
      seconds = '0' + seconds;
    }
    return "$minutes:$seconds";
  }

  void _navigateLocally(context) async {
    if (!fullscreen) {
      if (ModalRoute.of(context).willHandlePopInternally) {
        Navigator.of(context).pop();
      }
      return;
    }
    ModalRoute.of(context).addLocalHistoryEntry(LocalHistoryEntry(onRemove: () {
      if (fullscreen) toggleFullScreen();
    }));
  }

  void toggleFullScreen() {
    if (fullscreen) {
      OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
    } else {
      OrientationPlugin.forceOrientation(DeviceOrientation.landscapeRight);
    }
  }

  double _calculateAspectRatio(BuildContext context) {
    final width = screenSize.width;
    final height = screenSize.height;
    // return widget.playOptions.aspectRatio ?? controller.value.aspectRatio;
    return width > height ? width / height : height / width;
  }
}
