import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orientation/orientation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';
import 'package:http/http.dart' as http;
import 'package:yoyo_player/src/utils/utils.dart';
import 'package:yoyo_player/src/widget/widget_bottombar.dart';
import '../yoyo_player.dart';
import 'model/audio.dart';
import 'model/m3u8.dart';
import 'model/m3u8s.dart';
import 'responses/regex_response.dart';
import 'widget/top_chip.dart';

class YoYoPlayer extends StatefulWidget {
  ///Video[source],
  ///```dart
  ///url:"https://example.com/index.m3u8";
  ///```
  final String url;

  ///Video Player  style
  ///```dart
  ///videoStyle : VideoStyle(
  ///     play =  Icon(Icons.play_arrow),
  ///     pause = Icon(Icons.pause),
  ///     fullScreen =  Icon(Icons.fullScreen),
  ///     forward =  Icon(Icons.skip_next),
  ///     backward =  Icon(Icons.skip_previous),
  ///     playedColor = Colors.green,
  ///     qualitystyle = const TextStyle(
  ///     color: Colors.white,),
  ///      qaShowStyle = const TextStyle(
  ///      color: Colors.white,
  ///    ),
  ///   );
  ///```
  final VideoStyle videoStyle;

  /// Video Loading Style
  final VideoLoadingStyle videoLoadingStyle;

  /// Video AspectRatio [aspectRatio : 16 / 9 ]
  final double aspectRatio;

  /// video state fullScreen
  final void Function(bool fullScreenTurnedOn) onFullScreen;

  /// video Type
  final void Function(String videoType) onPlayingVideo;

  ///
  /// ```dart
  /// YoYoPlayer(
  /// //url = (m3u8[hls],.mp4,.mkv,)
  ///   url : "",
  /// //video style
  ///   videoStyle : VideoStyle(),
  /// //video loading style
  ///   videoLoadingStyle : VideoLoadingStyle(),
  /// //video aspect ratio
  ///   aspectRatio : 16/9,
  /// )
  /// ```
  YoYoPlayer({
    Key? key,
    required this.url,
    required this.aspectRatio,
    required this.videoStyle,
    required this.videoLoadingStyle,
    required this.onFullScreen,
    required this.onPlayingVideo,
  }) : super(key: key);

  @override
  _YoYoPlayerState createState() => _YoYoPlayerState();
}

class _YoYoPlayerState extends State<YoYoPlayer>
    with SingleTickerProviderStateMixin {
  //video play type (hls,mp4,mkv,offline)
  late String playType;
  // Animation Controller
  late AnimationController controlBarAnimationController;
  // Video Top Bar Animation
  late Animation<double> controlTopBarAnimation;
  // Video Bottom Bar Animation
  late Animation<double> controlBottomBarAnimation;
  // Video Player Controller
  late VideoPlayerController controller;
  // Video init error default :false
  bool hasInitError = false;
  // Video Total Time duration
  late String videoDuration;
  // Video Seed to
  late String videoSeek;
  // Video duration 1
  late Duration duration;
  // video seek second by user
  late double videoSeekSecond;
  // video duration second
  late double videoDurationSecond;
  //m3u8 data video list for user choice

  List<M3U8pass> yoyo = [];
  // m3u8 audio list

  List<AUDIO> audioList = [];
  // m3u8 temp data
  late String m3u8Content;
  // subtitle temp data
  late String subtitleContent;
  // menu show m3u8 list
  bool m3u8show = false;
  // video full screen
  bool fullScreen = false;
  // menu show
  bool showMenu = false;
  // auto show subtitle
  bool showSubtitles = false;
  // video status
  late bool offline;
  // video auto quality
  String m3u8quality = "Auto";
  // time for duration
  late Timer showTime;
  //Current ScreenSize
  Size get screenSize => MediaQuery.of(context).size;
  //
  @override
  void initState() {
    // getSub();
    urlCheck(widget.url);
    super.initState();

    /// Control bar animation
    controlBarAnimationController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    controlTopBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);
    controlBottomBarAnimation = Tween(begin: -(36.0 + 0.0 * 2), end: 0.0)
        .animate(controlBarAnimationController);
    var widgetsBinding = WidgetsBinding.instance;

    widgetsBinding!.addPostFrameCallback((callback) {
      widgetsBinding.addPersistentFrameCallback((callback) {
        if (context == null) return;
        var orientation = MediaQuery.of(context).orientation;
        late bool _fullscreen;
        if (orientation == Orientation.landscape) {
          //Horizontal screen
          _fullscreen = true;
          SystemChrome.setEnabledSystemUIOverlays([]);
        } else if (orientation == Orientation.portrait) {
          _fullscreen = false;
          SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
        }
        if (_fullscreen != fullScreen) {
          setState(() {
            fullScreen = !fullScreen;
            _navigateLocally(context);
            if (widget.onFullScreen != null) {
              widget.onFullScreen(fullScreen);
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
    m3u8clean();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoChildren = <Widget>[
      GestureDetector(
        onTap: () {
          toggleControls();
        },
        onDoubleTap: () {
          togglePlay();
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
    videoChildren.addAll(videoBuiltInChildren());
    return AspectRatio(
      aspectRatio: fullScreen
          ? calculateAspectRatio(context, screenSize)
          : widget.aspectRatio,
      child: controller.value.initialized
          ? Stack(children: videoChildren)
          : widget.videoLoadingStyle.loading,
    );
  }

  /// Video Player ActionBar
  Widget actionBar() {
    return showMenu
        ? Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 40,
              width: double.infinity,
              // color: Colors.yellow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 5,
                  ),
                  topChip(
                    Text(m3u8quality, style: widget.videoStyle.qualitystyle),
                    () {
                      // quality function
                      m3u8show = true;
                    },
                  ),
                  Container(
                    width: 5,
                  ),
                  InkWell(
                    onTap: () => toggleFullScreen(),
                    child: Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 5,
                  ),
                ],
              ),
            ),
          )
        : Container();
  }

  Widget m3u8list() {
    return m3u8show == true
        ? Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0, right: 5),
              child: SingleChildScrollView(
                child: Column(
                  children: yoyo
                      .map((e) => InkWell(
                            onTap: () {
                              m3u8quality = e.dataQuality;
                              m3u8show = false;
                              onSelectQuality(e);
                              print(
                                  "--- quality select ---\nquality : ${e.dataQuality}\nlink : ${e.dataURL}");
                            },
                            child: Container(
                                width: 90,
                                color: Colors.grey,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "${e.dataQuality}",
                                    style: widget.videoStyle.qaShowStyle,
                                  ),
                                )),
                          ))
                      .toList(),
                ),
              ),
            ),
          )
        : Container();
  }

  List<Widget> videoBuiltInChildren() {
    return [
      actionBar(),
      btm(),
      m3u8list(),
    ];
  }

  Widget btm() {
    return showMenu
        ? bottomBar(
            controller: controller,
            videoSeek: "$videoSeek",
            videoDuration: "$videoDuration",
            forwardIcon: widget.videoStyle.forward,
            backwardIcon: widget.videoStyle.backward,
            showMenu: showMenu,
            play: () => togglePlay())
        : Container();
  }

  void urlCheck(String url) {
    final netRegex = new RegExp(r'^(http|https):\/\/([\w.]+\/?)\S*');
    final isNetwork = netRegex.hasMatch(url);
    final a = Uri.parse(url);

    print("parse url data end : ${a.pathSegments.last}");
    if (isNetwork) {
      setState(() {
        offline = false;
      });
      if (a.pathSegments.last.endsWith("mkv")) {
        setState(() {
          playType = "MKV";
        });
        print("urlEnd : mkv");
        if (widget.onPlayingVideo != null) widget.onPlayingVideo("MKV");

        videoControlSetup(url);
      } else if (a.pathSegments.last.endsWith("mp4")) {
        setState(() {
          playType = "MP4";
        });
        print("urlEnd : mp4 $playType");
        if (widget.onPlayingVideo != null) widget.onPlayingVideo("MP4");

        print("urlEnd : mp4");
        videoControlSetup(url);
      } else if (a.pathSegments.last.endsWith("m3u8")) {
        setState(() {
          playType = "HLS";
        });
        if (widget.onPlayingVideo != null) widget.onPlayingVideo("M3U8");

        print("urlEnd : m3u8");
        videoControlSetup(url);
        getM3U8(url);
      } else {
        print("urlEnd : null");
        videoControlSetup(url);
        getM3U8(url);
      }
      print("--- Current Video Status ---\noffline : $offline");
    } else {
      setState(() {
        offline = true;
        print(
            "--- Current Video Status ---\noffline : $offline \n --- :3 done url check ---");
      });
      videoControlSetup(url);
    }
  }

// M3U8 Data Setup
  void getM3U8(String video) {
    if (yoyo.length > 0) {
      print("${yoyo.length} : data start clean");
      m3u8clean();
    }
    print("---- m3u8 fitch start ----\n$video\n--- please wait –––");
    m3u8video(video);
  }

  Future<M3U8s> m3u8video(String video) async {
    yoyo.add(M3U8pass(dataQuality: "Auto", dataURL: video));
    RegExp regExpAudio = new RegExp(
      RegexResponse.regexMEDIA,
      caseSensitive: false,
      multiLine: true,
    );
    RegExp regExp = new RegExp(
      r"#EXT-X-STREAM-INF:(?:.*,RESOLUTION=(\d+x\d+))?,?(.*)\r?\n(.*)",
      caseSensitive: false,
      multiLine: true,
    );
    setState(
      () {
        if (m3u8Content != null) {
          print("--- HLS Old Data ----\n$m3u8Content");
          m3u8Content = "";
        }
      },
    );
    if (m3u8Content == null && video != null) {
      http.Response response = await http.get(video);
      if (response.statusCode == 200) {
        m3u8Content = utf8.decode(response.bodyBytes);
      }
    }
    List<RegExpMatch> matches = regExp.allMatches(m3u8Content).toList();
    List<RegExpMatch> audioMatches =
        regExpAudio.allMatches(m3u8Content).toList();
    print(
        "--- HLS Data ----\n$m3u8Content \ntotal length: ${yoyo.length} \nfinish");

    matches.forEach(
      (RegExpMatch regExpMatch) async {
        String quality = (regExpMatch.group(1)).toString();
        String sourceURL = (regExpMatch.group(3)).toString();
        final netRegex = new RegExp(r'^(http|https):\/\/([\w.]+\/?)\S*');
        final netRegex2 = new RegExp(r'(.*)\r?\/');
        final isNetwork = netRegex.hasMatch(sourceURL);
        final match = netRegex2.firstMatch(video);
        String url;
        if (isNetwork) {
          url = sourceURL;
        } else {
          print(match);
          final dataURL = match!.group(0);
          url = "$dataURL$sourceURL";
          print("--- hls child url integration ---\nchild url :$url");
        }
        audioMatches.forEach(
          (RegExpMatch regExpMatch2) async {
            String audioURL = (regExpMatch2.group(1)).toString();
            final isNetwork = netRegex.hasMatch(audioURL);
            final match = netRegex2.firstMatch(video);
            String auURL = audioURL;
            if (isNetwork) {
              auURL = audioURL;
            } else {
              print(match);
              final auDataURL = match!.group(0);
              auURL = "$auDataURL$audioURL";
              print("url network audio  $url $audioURL");
            }
            audioList.add(AUDIO(url: auURL));
            print(audioURL);
          },
        );
        String audio = "";
        print("-- audio ---\naudio list length :${audio.length}");
        if (audioList.length != 0) {
          audio =
              """#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-medium",NAME="audio",AUTOSELECT=YES,DEFAULT=YES,CHANNELS="2",URI="${audioList.last.url}"\n""";
        } else {
          audio = "";
        }
        try {
          final Directory directory = await getApplicationDocumentsDirectory();
          final File file = File('${directory.path}/yoyo$quality.m3u8');
          await file.writeAsString(
              """#EXTM3U\n#EXT-X-INDEPENDENT-SEGMENTS\n$audio#EXT-X-STREAM-INF:CLOSED-CAPTIONS=NONE,BANDWIDTH=1469712,RESOLUTION=$quality,FRAME-RATE=30.000\n$url""");
        } catch (e) {
          print("Couldn't write file");
        }
        yoyo.add(M3U8pass(dataQuality: quality, dataURL: url));
      },
    );
    M3U8s m3u8s = M3U8s(m3u8s: yoyo);
    print(
        "--- m3u8 file write ---\n${yoyo.map((e) => e.dataQuality == e.dataURL).toList()}\nlength : ${yoyo.length}\nSuccess");
    return m3u8s;
  }

// Video controller
  void videoControlSetup(String url) {
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
  }

  void createHideControlBarTimer() {
    clearHideControlBarTimer();
    showTime = Timer(Duration(milliseconds: 5000), () {
      if (controller != null && controller.value.isPlaying) {
        if (showMenu) {
          setState(() {
            showMenu = false;
            m3u8show = false;
            controlBarAnimationController.reverse();
          });
        }
      }
    });
  }

  void clearHideControlBarTimer() {
    showTime.cancel();
  }

  void toggleControls() {
    clearHideControlBarTimer();

    if (!showMenu) {
      showMenu = true;
      createHideControlBarTimer();
    } else {
      m3u8show = false;
      showMenu = false;
    }
    setState(() {
      if (showMenu) {
        controlBarAnimationController.forward();
      } else {
        controlBarAnimationController.reverse();
      }
    });
  }

  void togglePlay() {
    createHideControlBarTimer();
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  void videoInit(String url) {
    if (offline == false) {
      print(
          "--- Player Status ---\nplay url : $url\noffline : $offline\n--- start playing –––");

      if (playType == "MP4") {
        // Play MP4
        controller =
            VideoPlayerController.network(url, formatHint: VideoFormat.other)
              ..initialize();
      } else if (playType == "MKV") {
        controller =
            VideoPlayerController.network(url, formatHint: VideoFormat.dash)
              ..initialize();
      } else if (playType == "HLS") {
        controller =
            VideoPlayerController.network(url, formatHint: VideoFormat.hls)
              ..initialize()
                  .then((_) => setState(() => hasInitError = false))
                  .catchError((e) => setState(() => hasInitError = true));
      }
    } else {
      print(
          "--- Player Status ---\nplay url : $url\noffline : $offline\n--- start playing –––");
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
    if (!fullScreen) {
      if (ModalRoute.of(context)!.willHandlePopInternally) {
        Navigator.of(context).pop();
      }
      return;
    }
    ModalRoute.of(context)!
        .addLocalHistoryEntry(LocalHistoryEntry(onRemove: () {
      if (fullScreen) toggleFullScreen();
    }));
  }

  void onSelectQuality(M3U8pass data) async {
    controller.value.isPlaying ? controller.pause() : controller.pause();
    if (data.dataQuality == "Auto") {
      videoControlSetup(data.dataURL);
    } else {
      try {
        String text;
        final Directory directory = await getApplicationDocumentsDirectory();
        final File file =
            File('${directory.path}/yoyo${data.dataQuality}.m3u8');
        print("read file success");
        text = await file.readAsString();
        print("data : $text  :: data");
        localM3U8play(file);
        // videoControlSetup(file);
      } catch (e) {
        print("Couldn't read file ${data.dataQuality} e: $e");
      }
      print("data : ${data.dataQuality}");
    }
  }

  void localM3U8play(File file) {
    controller = VideoPlayerController.file(
      file,
    )..initialize()
        .then((_) => setState(() => hasInitError = false))
        .catchError((e) => setState(() => hasInitError = true));
    controller.addListener(listener);
    controller.play();
  }

  void m3u8clean() async {
    print(yoyo.length);
    for (int i = 2; i < yoyo.length; i++) {
      try {
        final Directory directory = await getApplicationDocumentsDirectory();
        final File file = File('${directory.path}/${yoyo[i].dataQuality}.m3u8');
        file.delete();
        print("delete success $file");
      } catch (e) {
        print("Couldn't delete file $e");
      }
    }
    try {
      print("Audio m3u8 list clean");
      audioList.clear();
    } catch (e) {
      print("Audio list clean error $e");
    }
    audioList.clear();
    try {
      print("m3u8 data list clean");
      yoyo.clear();
    } catch (e) {
      print("m3u8 video list clean error $e");
    }
  }

  void toggleFullScreen() {
    if (fullScreen) {
      OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
    } else {
      OrientationPlugin.forceOrientation(DeviceOrientation.landscapeRight);
    }
  }
}
