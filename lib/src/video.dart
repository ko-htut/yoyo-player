import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_wake/flutter_screen_wake.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:orientation/orientation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';
import 'package:yoyo_player/src/responses/play_response.dart';
import 'package:yoyo_player/src/utils/utils.dart';
import 'package:yoyo_player/src/widget/widget_bottombar.dart';
import 'package:yoyo_player/yoyo_player.dart';

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

  final dynamic isVideoProgressenable;
  final dynamic contentViewId;
  final timeRecordVideoProgress;
  final domianUrl;
  final contentID;
  final authToken;

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
  final VideoStyle? videoStyle;

  /// Video Loading Style
  final VideoLoadingStyle? videoLoadingStyle;

  /// Video AspectRatio [aspectRatio : 16 / 9 ]
  final double aspectRatio;

  /// video state fullScreen
  final void Function(bool fullScreenTurnedOn)? onFullScreen;

  /// video Type
  final void Function(String videoType)? onPlayingVideo;

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
    this.videoStyle,
    this.videoLoadingStyle,
    this.onFullScreen,
    this.onPlayingVideo,
    this.isVideoProgressenable,
    this.contentViewId,
    this.timeRecordVideoProgress,
    this.domianUrl,
    this.contentID,
    this.authToken,
  }) : super(key: key);

  @override
  _YoYoPlayerState createState() => _YoYoPlayerState();
}

class _YoYoPlayerState extends State<YoYoPlayer>
    with SingleTickerProviderStateMixin {
  //video play type (hls,mp4,mkv,offline)
  String? playType;
  // Animation Controller
  late AnimationController controlBarAnimationController;
  // Video Top Bar Animation
  Animation<double>? controlTopBarAnimation;
  // Video Bottom Bar Animation
  Animation<double>? controlBottomBarAnimation;
  // Video Player Controller
  VideoPlayerController? controller;
  // Video init error default :false
  bool hasInitError = false;
  // Video Total Time duration
  String? videoDuration;
  // Video Seed to
  String? videoSeek;
  // Video duration 1
  Duration? duration;
  // video seek second by user
  double? videoSeekSecond;
  // video duration second
  double? videoDurationSecond;

  //m3u8 data video list for user choice
  List<M3U8pass> yoyo = [];
  List<double> androidplayBackspeed = [
    1.0,
    1.2,
    1.4,
    1.6,
    1.8,
    2.0,
    2.25,
    2.5,
  ];
  List<double> iosplayBackspeed = [
    1.0,
    1.2,
    1.3,
    1.4,
    1.5,
    1.6,
    1.7,
    1.8,
    2.0,
  ];

  List<double> getplaybackspeedaccordingtoPlateform() {
    if (Platform.isAndroid) {
      return androidplayBackspeed;
    } else {
      return iosplayBackspeed;
    }
  }

  // m3u8 audio list
  List<AUDIO> audioList = [];
  // m3u8 temp data
  String? m3u8Content;
  // subtitle temp data
  String? subtitleContent;
  // menu show m3u8 list
  bool m3u8show = false;
  bool m3u8showspeed = false;
  // video full screen
  bool fullScreen = false;
  // menu show
  bool showMenu = false;
  // auto show subtitle
  bool showSubtitles = false;
  // video status
  bool? offline;
  // video auto quality
  String? m3u8quality = "Auto";
  double? playbackSpeed = 1.0;
  // time for duration
  Timer? showTime;
  //Current ScreenSize
  Size get screenSize => MediaQuery.of(context).size;
  FlutterSecureStorage? storage;
  int? currentPosition;
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

    widgetsBinding.addPostFrameCallback((callback) async {
      storage = FlutterSecureStorage();
      try {
        final z = await storage?.read(
          key: widget.url,
        );
        if (z != null) {
          currentPosition = int.tryParse(z);
        }
      } catch (e) {
        print(e);
      }

      debugPrint(
          "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx ${currentPosition.toString()}");
      // widgetsBinding.addPersistentFrameCallback((callback) {
      var orientation = MediaQuery.of(context).orientation;
      bool? _fullscreen;
      if (orientation == Orientation.landscape) {
        //Horizontal screen
        _fullscreen = true;
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
      } else if (orientation == Orientation.portrait) {
        _fullscreen = false;
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
            overlays: SystemUiOverlay.values);
      }
      if (_fullscreen != fullScreen) {
        setState(() {
          fullScreen = !fullScreen;
          _navigateLocally(context);
          if (widget.onFullScreen != null) {
            widget.onFullScreen!(fullScreen);
          }
        });
      }
      //
      widgetsBinding.scheduleFrame();
      // });
    });
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    FlutterScreenWake.keepOn(true);
  }

  @override
  void dispose() {
    m3u8clean();
    controller!.dispose();
    storage?.write(
        key: widget.url,
        value: controller!.value.position.inSeconds.toString());
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (timer != null) {
      timer?.cancel();
    }

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
              aspectRatio: controller!.value.aspectRatio,
              child: VideoPlayer(controller!),
            )),
          ),
        ),
      ),
    ];
    videoChildren.addAll(videoBuiltInChildren());
    return AspectRatio(
      aspectRatio: MediaQuery.of(context).orientation == Orientation.landscape
          ?
          // MediaQuery.of(context).size.width /
          //     MediaQuery.of(context).size.height
          // :

          calculateAspectRatio(context, screenSize)
          //     :
          : widget.aspectRatio,
      child: controller!.value.isInitialized
          ? Stack(children: videoChildren)
          : widget.videoLoadingStyle!.loading,
    );
  }

  /// Video Player ActionBar
  Widget actionBar() {
    return showMenu
        ? SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 40,
                width: double.infinity,
                // color: Colors.yellow,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 5,
                      ),
                      topChip(
                        Text(playbackSpeed.toString() + " x",
                            style: widget.videoStyle!.qualitystyle),
                        () {
                          debugPrint("speeed");
                          setState(() {
                            m3u8showspeed = !m3u8showspeed;
                            m3u8show = false;
                          });
                        },
                      ),
                      topChip(
                        Text(m3u8quality!,
                            style: widget.videoStyle!.qualitystyle),
                        () {
                          // quality function
                          setState(() {
                            m3u8show = !m3u8show;
                            m3u8showspeed = false;
                          });
                        },
                      ),
                      InkWell(
                        onTap: () => toggleFullScreen(),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          padding:
                              EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                          decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(5)),
                          child: Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 33,
                          ),
                        ),
                      ),
                      Container(
                        width: 17,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        : Container();
  }

  Widget m3u8listspeed() {
    return m3u8showspeed == true
        ? Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0, right: 5),
              child: SingleChildScrollView(
                child: Column(
                  children: getplaybackspeedaccordingtoPlateform()
                      .map((e) => InkWell(
                            onTap: () {
                              setState(() {
                                controller!.setPlaybackSpeed(e);
                                playbackSpeed = e;
                                m3u8showspeed = false;
                              });

                              debugPrint("--- speed select : $e");
                            },
                            child: Container(
                                width: 90,
                                color: Colors.grey,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "${e.toString()} x",
                                    style: widget.videoStyle!.qaShowStyle,
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
                              setState(() {
                                m3u8quality = e.dataQuality;
                                m3u8show = false;
                              });
                              onSelectQuality(e);
                              debugPrint(
                                  "--- quality select ---\nquality : ${e.dataQuality}\nlink : ${e.dataURL}");
                            },
                            child: Container(
                                width: 90,
                                color: Colors.grey,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    "${e.dataQuality}",
                                    style: widget.videoStyle!.qaShowStyle,
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
      m3u8listspeed(),
    ];
  }

  Widget btm() {
    return showMenu
        ? bottomBar(
            controller: controller,
            videoSeek: "$videoSeek",
            videoDuration: "$videoDuration",
            forwardIcon: widget.videoStyle!.forward,
            backwardIcon: widget.videoStyle!.backward,
            showMenu: showMenu,
            playbackSpeed: playbackSpeed,
            forwrad: () => forward(),
            rewind: () => rewindBack(),
            play: () => togglePlay())
        : Container();
  }

  void urlCheck(String url) {
    final netRegex = new RegExp(r'^(http|https):\/\/([\w.]+\/?)\S*');
    final isNetwork = netRegex.hasMatch(url);
    final a = Uri.parse(url);

    debugPrint("parse url data end : ${a.pathSegments.last}");
    if (isNetwork) {
      setState(() {
        offline = false;
      });
      if (a.pathSegments.last.endsWith("mkv")) {
        setState(() {
          playType = "MKV";
        });
        debugPrint("urlEnd : mkv");
        if (widget.onPlayingVideo != null) widget.onPlayingVideo!("MKV");

        videoControlSetup(url);
      } else if (a.pathSegments.last.endsWith("mp4")) {
        setState(() {
          playType = "MP4";
        });
        debugPrint("urlEnd : mp4 $playType");
        if (widget.onPlayingVideo != null) widget.onPlayingVideo!("MP4");

        debugPrint("urlEnd : mp4");
        videoControlSetup(url);
      } else if (a.pathSegments.last.endsWith("m3u8")) {
        setState(() {
          playType = "HLS";
        });
        if (widget.onPlayingVideo != null) widget.onPlayingVideo!("M3U8");

        debugPrint("urlEnd : m3u8");
        videoControlSetup(url);
        getM3U8(url);
      } else {
        debugPrint("urlEnd : null");
        videoControlSetup(url);
        getM3U8(url);
      }
      debugPrint("--- Current Video Status ---\noffline : $offline");
    } else {
      setState(() {
        offline = true;
        debugPrint(
            "--- Current Video Status ---\noffline : $offline \n --- :3 done url check ---");
      });
      videoControlSetup(url);
    }
  }

// M3U8 Data Setup
  void getM3U8(String video) {
    try {
      if (yoyo.length > 0) {
        debugPrint("${yoyo.length} : data start clean");
        m3u8clean();
      }
      debugPrint("---- m3u8 fitch start ----\n$video\n--- please wait –––");
      m3u8video(video);
    } catch (e) {
      print(e);
    }
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
          debugPrint("--- HLS Old Data ----\n$m3u8Content");
          m3u8Content = null;
        }
      },
    );
    if (m3u8Content == null && video != null) {
      http.Response response = await http.get(Uri.parse(video));
      if (response.statusCode == 200) {
        m3u8Content = utf8.decode(response.bodyBytes);
      }
    }
    List<RegExpMatch> matches = regExp.allMatches(m3u8Content!).toList();
    List<RegExpMatch> audioMatches =
        regExpAudio.allMatches(m3u8Content!).toList();
    debugPrint(
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
          debugPrint("--- hls child url integration ---\nchild url :$url");
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
              debugPrint("url network audio  $url $audioURL");
            }
            audioList.add(AUDIO(url: auURL));
            debugPrint(audioURL);
          },
        );
        String audio = "";
        debugPrint("-- audio ---\naudio list length :${audio.length}");
        if (audioList.length != 0) {
          audio =
              """#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-medium",NAME="audio",AUTOSELECT=YES,DEFAULT=YES,CHANNELS="2",URI="${audioList.last.url}"\n""";
        } else {
          audio = "";
        }
        try {
          final Directory directory = await getApplicationSupportDirectory();
          final File file = File('${directory.path}/yoyo$quality.m3u8');
          await file.writeAsString(
              """#EXTM3U\n#EXT-X-INDEPENDENT-SEGMENTS\n$audio#EXT-X-STREAM-INF:CLOSED-CAPTIONS=NONE,BANDWIDTH=1469712,RESOLUTION=$quality,FRAME-RATE=30.000\n$url""");
        } catch (e) {
          debugPrint("Couldn't write file");
        }
        yoyo.add(M3U8pass(dataQuality: quality, dataURL: url));
      },
    );
    M3U8s m3u8s = M3U8s(m3u8s: yoyo);
    debugPrint(
        "--- m3u8 file write ---\n${yoyo.map((e) => e.dataQuality == e.dataURL).toList()}\nlength : ${yoyo.length}\nSuccess");
    return m3u8s;
  }

// Video controller
  void videoControlSetup(String? url) {
    videoInit(url);
    controller!.addListener(() async {
      if (controller!.value.isInitialized && controller!.value.isPlaying) {
        if (!await Wakelock.enabled) {
          await Wakelock.enable();
        }

        setState(() {
          videoDuration = convertDurationToString(controller!.value.duration);
          videoSeek = convertDurationToString(controller!.value.position);
          videoSeekSecond = controller!.value.position.inSeconds.toDouble();
          videoDurationSecond = controller!.value.duration.inSeconds.toDouble();
        });

        if (widget.isVideoProgressenable == 1 && widget.contentViewId != null) {
          if (controller!.value.position.inSeconds != null) {
            print(controller!.value.position.inSeconds);
            controller!.value.position.inSeconds;
            final second = controller!.value.position.inSeconds;
            if (second != null) {
              if (((second / 60).floor()) != lastProgressMinute) {
                lastProgressMinute = (second / 60).floor();
                watchedAnalaysis.add((second / 60).floor());
              }
            }
          }
        }
      } else {
        if (await Wakelock.enabled) {
          await Wakelock.disable();
          setState(() {});
        }
      }
    });
    if (widget.isVideoProgressenable == 1 && widget.contentViewId != null) {
      timer = Timer.periodic(
          Duration(minutes: widget.timeRecordVideoProgress ?? 3), (timer) {
        if (watchedAnalaysis.length != 0) {
          updateVideoProgress();
        }
      });
    }
    controller!.play();
    setState(() {
      controller!.setPlaybackSpeed(playbackSpeed!);
      // controller!
      //     .seekTo(Duration(seconds: int.tryParse(currentPosition.toString())!));
    });
  }

  Set<dynamic> watchedAnalaysis = {};

  dynamic lastProgressMinute = -1;
  Timer? timer;

  Future<void> updateVideoProgress() async {
    try {
      print(watchedAnalaysis.toList());
      final url = widget.domianUrl;

      if (watchedAnalaysis.isNotEmpty) {
        final respond = await http.post(Uri.parse(url),
            body: json.encode({
              "contentViewId": widget.contentViewId.toString(),
              "watchedMinutes": watchedAnalaysis.toList(),
              "contentId": widget.contentID.toString(),
              "video_duration":
                  (((controller!.value.duration.inSeconds) / 60).ceil())
                      .toString(),
            }),
            headers: {
              "Accept": "application/json",
              'Content-Type': 'application/json',
              "Authorization": "Bearer ${widget.authToken}",
            });
        print(respond.body);
        if (respond.statusCode == 200) {
          watchedAnalaysis = {};
        }
      }
    } catch (e) {
      print(e);
    }
  }

// video Listener
  void listener() async {}

  void createHideControlBarTimer() {
    clearHideControlBarTimer();
    showTime = Timer(Duration(milliseconds: 70000), () {
      if (controller != null && controller!.value.isPlaying) {
        if (showMenu) {
          setState(() {
            showMenu = false;
            m3u8show = false;
            m3u8showspeed = false;

            controlBarAnimationController.reverse();
          });
        }
      }
    });
  }

  void clearHideControlBarTimer() {
    showTime?.cancel();
  }

  void toggleControls() {
    clearHideControlBarTimer();

    if (!showMenu && controller != null) {
      showMenu = true;
      createHideControlBarTimer();
    } else {
      m3u8show = false;
      m3u8showspeed = false;
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

  void forward() {
    fastForward(controller: controller!);
    if (Platform.isIOS) {
      controller!.setPlaybackSpeed(playbackSpeed!).then(
          (value) => controller!.pause().then((value) => controller!.play()));
    }
  }

  void rewindBack() {
    rewind(controller!);
    if (Platform.isIOS) {
      controller!.setPlaybackSpeed(playbackSpeed!).then(
          (value) => controller!.pause().then((value) => controller!.play()));
    }
  }

  void togglePlay() {
    createHideControlBarTimer();
    if (controller!.value.isPlaying) {
      controller!.pause();
    } else {
      controller!.play();
    }
    setState(() {});
  }

  void videoInit(String? url) {
    if (offline == false) {
      debugPrint(
          "--- Player Status ---\nplay url : $url\noffline : $offline\n--- start playing –––");

      if (playType == "MP4") {
        // Play MP4
        controller = controller = VideoPlayerController.networkUrl(
            Uri.parse(url!),
            formatHint: VideoFormat.other)
          ..initialize().then((_) {
            if (currentPosition != null) {
              controller!.seekTo(
                  Duration(seconds: int.tryParse(currentPosition.toString())!));
            }
          });
      } else if (playType == "MKV") {
        controller = controller = VideoPlayerController.networkUrl(
            Uri.parse(url!),
            formatHint: VideoFormat.dash)
          ..initialize().then((_) {
            if (currentPosition != null) {
              controller!.seekTo(
                  Duration(seconds: int.tryParse(currentPosition.toString())!));
            }
          });
      } else if (playType == "HLS") {
        controller = VideoPlayerController.networkUrl(Uri.parse(url!),
            formatHint: VideoFormat.hls)
          ..initialize().then((_) {
            if (currentPosition != null) {
              controller!.seekTo(
                  Duration(seconds: int.tryParse(currentPosition.toString())!));
            }
            setState(() => hasInitError = false);
          }).catchError((e) {
            debugPrint(e);
            setState(() => hasInitError = true);
          });
      }
    } else {
      debugPrint(
          "--- Player Status ---\nplay url : $url\noffline : $offline\n--- start playing –––");
      controller = VideoPlayerController.file(File(url!))
        ..initialize().then((_) {
          if (currentPosition != null) {
            controller!.seekTo(
                Duration(seconds: int.tryParse(currentPosition.toString())!));
            setState(() => hasInitError = false);
          }
        }).catchError((e) {
          debugPrint(e);
          setState(() => hasInitError = true);
        });
    }
  }

  String convertDurationToString(Duration duration) {
    var minutes = (duration.inMinutes % 60).toString();
    if (minutes.length == 1) {
      minutes = '0' + minutes;
    }
    var seconds = (duration.inSeconds % 60).toString();
    if (seconds.length == 1) {
      seconds = '0' + seconds;
    }
    var hour = (duration.inHours).toString();
    if (hour.length == 1) {
      hour = '0' + hour;
    }
    return "$hour:$minutes:$seconds";
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
    controller!.value.isPlaying ? controller!.pause() : controller!.pause();
    if (data.dataQuality == "Auto") {
      videoControlSetup(data.dataURL);
    } else {
      try {
        String text;
        final Directory directory = await getApplicationSupportDirectory();
        final File file =
            File('${directory.path}/yoyo${data.dataQuality}.m3u8');
        debugPrint("read file success");
        text = await file.readAsString();
        debugPrint("data : $text  :: data");
        storage?.write(
            key: widget.url,
            value: controller!.value.position.inSeconds.toString());

        localM3U8play(data.dataURL!);
        // videoControlSetup(file);
      } catch (e) {
        debugPrint("Couldn't read file ${data.dataQuality} e: $e");
      }
      debugPrint("data : ${data.dataQuality}");
    }
  }

  void localM3U8play(String url) async {
    controller!.dispose();

    // timer.cancel();

    final lastPlayedPos = await controller!.position;
    controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
    )..initialize().then((_) async {
        setState(() => hasInitError = false);
        if (lastPlayedPos != null) {
          controller!.seekTo(lastPlayedPos);
        }
        setState(() {
          controller!.setPlaybackSpeed(playbackSpeed!);
        });

        // controller!.play();
      }).catchError((e) {
        setState(() => hasInitError = true);
        debugPrint('Init local file error $e');
      });

    controller!.addListener(() async {
      if (controller!.value.isInitialized && controller!.value.isPlaying) {
        if (!await Wakelock.enabled) {
          await Wakelock.enable();
        }

        setState(() {
          videoDuration = convertDurationToString(controller!.value.duration);
          videoSeek = convertDurationToString(controller!.value.position);
          videoSeekSecond = controller!.value.position.inSeconds.toDouble();
          videoDurationSecond = controller!.value.duration.inSeconds.toDouble();
        });

        if (widget.isVideoProgressenable == 1 && widget.contentViewId != null) {
          if (controller!.value.position.inSeconds != null) {
            print(controller!.value.position.inSeconds);
            controller!.value.position.inSeconds;
            final second = controller!.value.position.inSeconds;
            if (second != null) {
              if (((second / 60).floor()) != lastProgressMinute) {
                lastProgressMinute = (second / 60).floor();
                watchedAnalaysis.add((second / 60).floor());
              }
            }
          }
        }
      } else {
        if (await Wakelock.enabled) {
          await Wakelock.disable();
          setState(() {});
        }
      }
      if (widget.isVideoProgressenable == 1 && widget.contentViewId != null) {
        timer = Timer.periodic(
            Duration(minutes: widget.timeRecordVideoProgress ?? 3), (timer) {
          if (watchedAnalaysis.length > 0) {
            updateVideoProgress();
          }
        });
      }
    });
    controller!.play();
    setState(() {
      controller!.setPlaybackSpeed(playbackSpeed!);
    });
  }

  void m3u8clean() async {
    print(yoyo.length);
    for (int i = 2; i < yoyo.length; i++) {
      try {
        final Directory directory = await getApplicationSupportDirectory();
        final File file = File('${directory.path}/${yoyo[i].dataQuality}.m3u8');
        file.delete();
        debugPrint("delete success $file");
      } catch (e) {
        debugPrint("Couldn't delete file $e");
      }
    }
    try {
      debugPrint("Audio m3u8 list clean");
      audioList.clear();
    } catch (e) {
      debugPrint("Audio list clean error $e");
    }
    // audioList.clear();
    try {
      debugPrint("m3u8 data list clean");
      yoyo.clear();
    } catch (e) {
      debugPrint("m3u8 video list clean error $e");
    }
  }

  void toggleFullScreen() {
    // if (fullScreen) {
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      debugPrint("full up");
      OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
    } else {
      debugPrint("full land right");
      OrientationPlugin.forceOrientation(DeviceOrientation.landscapeRight);
    }
  }
}
