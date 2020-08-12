import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orientation/orientation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock/wakelock.dart';
import 'package:yoyo_player/src/video_style.dart';
import 'package:yoyo_player/yoyo_player.dart';
import 'model/audio.dart';
import 'model/m3u8.dart';
import 'model/m3u8s.dart';
import 'model/subtitle.dart';
import 'model/subtitles.dart';

typedef VideoCallback<T> = void Function(T t);

class YoYoPlayer extends StatefulWidget {
  ///Video source
  final String url;

  /// Subtitle .srt source
  final String subtitle;

  /// Video Player  style
  final VideoStyle videoStyle;

  /// Video Loading Style
  final VideoLoadingStyle videoLoadingStyle;

  /// Video AspectRaitio [aspectRatio : 16 / 9 ]
  final double aspectRatio;

  /// Video Subtitle Style
  final SubtitleStyle subtitleStyle;

  /// video state fullscreen
  final VideoCallback<bool> onfullscreen;

  /// yoyo_player is a video player that allows you to select HLS video streaming by selecting the quality
  YoYoPlayer(
      {Key key,
      @required this.url,
      this.subtitle,
      @required this.aspectRatio,
      this.videoStyle,
      this.videoLoadingStyle,
      this.onfullscreen,
      this.subtitleStyle})
      : super(key: key);

  @override
  _YoYoPlayerState createState() => _YoYoPlayerState();
}

class _YoYoPlayerState extends State<YoYoPlayer> {
  AnimationController controlBarAnimationController;
  Animation<double> controlTopBarAnimation;
  Animation<double> controlBottomBarAnimation;
  VideoPlayerController controller;
  bool hasInitError = false;
  String videoDuration;
  String videoSeek;
  Duration duration;
  Duration duration2;
  double videoSeekSecond;
  double videoDurationSecond;
  //m3u8 data video list
  List<M3U8pass> m3u8List = List();
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
  @override
  void initState() {
    super.initState();
    urlcheck(widget.url);
    getsub(widget.subtitle);
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

  void urlcheck(String url) {
    final netRegx = new RegExp(r'^(http|https):\/\/([\w.]+\/?)\S*');
    final isNetwork = netRegx.hasMatch(url);
    if (isNetwork) {
      setState(() {
        offline = false;
      });
      videoControllSetup(url);
      getm3u8(url);
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

  void getm3u8(String video) {
    if (m3u8List.length > 0) {
      print("${m3u8List.length} : data start clean");
      m3u8clean();
    }
    print("fet new data form $video data start");
    m3u8video(video);
  }

  void getsub(String sub) {
    if (sub != null) {
      setState(() {
        showSubtitles = true;
        sublistener = true;
      });
      _subtitleWatcher(controller, sub: sub);
    }
  }

  Future<M3U8s> m3u8video(String video) async {
    m3u8List.add(M3U8pass(dataquality: "Auto", dataurl: video));

    RegExp regExp = new RegExp(
      r"#EXT-X-STREAM-INF:(?:.*,RESOLUTION=(\d+x\d+))?,?(.*)\r?\n(.*)",
      caseSensitive: false,
      multiLine: true,
    );
    RegExp regExpaudio = new RegExp(
      r"""^#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="(.*)",NAME="(.*)",AUTOSELECT=(.*),DEFAULT=(.*),CHANNELS="(.*)",URI="(.*)""",
      caseSensitive: false,
      multiLine: true,
    );
    if (m3u8Content == null && widget.url != null) {
      http.Response response = await http.get(widget.url);
      if (response.statusCode == 200) {
        m3u8Content = utf8.decode(response.bodyBytes);
      }
    }
    List<RegExpMatch> matches = regExp.allMatches(m3u8Content).toList();
    List<RegExpMatch> audiomatches =
        regExpaudio.allMatches(m3u8Content).toList();
    matches.forEach(
      (RegExpMatch regExpMatch) async {
        String quality = (regExpMatch.group(1)).toString();
        String sourceurl = (regExpMatch.group(3)).toString();
        final netRegx = new RegExp(r'^(http|https):\/\/([\w.]+\/?)\S*');
        final netRegx2 = new RegExp(r'(.*)\r?\/');
        final isNetwork = netRegx.hasMatch(sourceurl);
        final match = netRegx2.firstMatch(video);
        String url = sourceurl;
        if (isNetwork) {
          url = sourceurl;
        } else {
          print(match);
          final dataurl = match.group(0);
          url = "$dataurl$sourceurl";
          print("url network 2 $url $dataurl");
        }
        audiomatches.forEach(
          (RegExpMatch regExpMatch2) async {
            String audiourl = (regExpMatch2.group(6)).toString();
            audioList.add(AUDIO(url: audiourl));
            print(audiourl);
          },
        );
        String audio = "";
        print(audioList.length);
        if (audioList.length != 0) {
          audio =
              """#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-medium",NAME="audio",AUTOSELECT=YES,DEFAULT=YES,CHANNELS="2",URI="${audioList.last.url}"\n""";
        } else {
          audio = "";
        }
        try {
          final Directory directory = await getApplicationDocumentsDirectory();
          final File file = File('${directory.path}/$quality.m3u8');
          await file.writeAsString(
              """#EXTM3U\n#EXT-X-INDEPENDENT-SEGMENTS\n$audio#EXT-X-STREAM-INF:CLOSED-CAPTIONS=NONE,BANDWIDTH=1469712,RESOLUTION=$quality,FRAME-RATE=30.000\n$url """);
        } catch (e) {
          print("Couldn't write file");
        }
        m3u8List.add(M3U8pass(dataquality: quality, dataurl: url));
      },
    );
    M3U8s m3u8s = M3U8s(m3u8s: m3u8List);
    return m3u8s;
  }

  Future<Subtitles> getSubtitles(String subtitleUrl) async {
    RegExp regExp = new RegExp(
      // r"^((\d{2}):(\d{2}):(\d{2})\.(\d+)) +--> +((\d{2}):(\d{2}):(\d{2})\.(\d{3})).*[\r\n]+\s*((?:(?!\r?\n\r?).)*)",
      r"^((\d{2}):(\d{2}):(\d{2}),(\d{3})) +--> +((\d{2}):(\d{2}):(\d{2}),(\d{2})).*[\r\n]+\s*((?:(?!\r?\n\r?).)*)",
      caseSensitive: false,
      multiLine: true,
    );
    if (subtitleContent == null && subtitleUrl != null) {
      http.Response response = await http.get(subtitleUrl);
      if (response.statusCode == 200) {
        subtitleContent = utf8.decode(response.bodyBytes);
      }
    }
    print(subtitleContent);

    List<RegExpMatch> matches = regExp.allMatches(subtitleContent).toList();
    List<Subtitle> subtitleList = List();
    print("print ${subtitleList.length}");
    matches.forEach((RegExpMatch regExpMatch) {
      print("print startTimeHours : ${regExpMatch.group(2)}");
      int startTimeHours = int.parse(regExpMatch.group(2));
      int startTimeMinutes = int.parse(regExpMatch.group(3));
      int startTimeSeconds = int.parse(regExpMatch.group(4));
      int startTimeMilliseconds = int.parse(regExpMatch.group(5));

      int endTimeHours = int.parse(regExpMatch.group(7));
      int endTimeMinutes = int.parse(regExpMatch.group(8));
      int endTimeSeconds = int.parse(regExpMatch.group(9));
      int endTimeMilliseconds = int.parse(regExpMatch.group(10));
      String text = (regExpMatch.group(11)).toString();

      print(text);

      Duration startTime = Duration(
          hours: startTimeHours,
          minutes: startTimeMinutes,
          seconds: startTimeSeconds,
          milliseconds: startTimeMilliseconds);
      Duration endTime = Duration(
          hours: endTimeHours,
          minutes: endTimeMinutes,
          seconds: endTimeSeconds,
          milliseconds: endTimeMilliseconds);

      subtitleList.add(
          Subtitle(startTime: startTime, endTime: endTime, text: text.trim()));
    });

    Subtitles subtitles = Subtitles(subtitles: subtitleList);
    print("subtitles");
    return subtitles;
  }

  void onselectquality(M3U8pass data) async {
    controller.value.isPlaying ? controller.pause() : controller.pause();
    if (data.dataquality == "Auto") {
      videoControllSetup(data.dataurl);
    } else {
      try {
        String text;
        final Directory directory = await getApplicationDocumentsDirectory();
        final File file = File('${directory.path}/${data.dataquality}.m3u8');
        print("read file success");
        text = await file.readAsString();
        print("data : $text");
        localm3u8play(file);
        // videoControllSetup(file);
      } catch (e) {
        print("Couldn't read file ${data.dataquality} e: $e");
      }
      print("data : ${data.dataquality}");
    }
  }

  void localm3u8play(File file) {
    controller = VideoPlayerController.file(
      file,
    )..initialize()
        .then((_) => setState(() => hasInitError = false))
        .catchError((e) => setState(() => hasInitError = true));
    controller.addListener(listener);
    controller.play();
    controller.seekTo(duration2);
  }

  void toggleFullScreen() {
    if (fullscreen) {
      OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
    } else {
      OrientationPlugin.forceOrientation(DeviceOrientation.landscapeRight);
    }
  }

  void createHideControlbarTimer() {
    clearHideControlbarTimer();
    showTime = Timer(Duration(milliseconds: 5000), () {
      if (controller != null && controller.value.isPlaying) {
        if (showMeau) {
          setState(() {
            showMeau = false;
            m3u8show = false;
            controlBarAnimationController.reverse();
          });
        }
      }
    });
  }

  void clearHideControlbarTimer() {
    showTime?.cancel();
  }

  void toggleControls() {
    clearHideControlbarTimer();

    if (!showMeau) {
      showMeau = true;
      createHideControlbarTimer();
    } else {
      m3u8show = false;
      showMeau = false;
    }
    setState(() {
      if (showMeau) {
        controlBarAnimationController.forward();
      } else {
        controlBarAnimationController.reverse();
      }
    });
  }

  void togglePlay() {
    createHideControlbarTimer();
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
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

  double _calculateAspectRatio(BuildContext context) {
    final width = screenSize.width;
    final height = screenSize.height;
    // return widget.playOptions.aspectRatio ?? controller.value.aspectRatio;
    return width > height ? width / height : height / width;
  }

  void fastForward() {
    if (controller.value.duration.inSeconds -
            controller.value.position.inSeconds >
        10) {
      controller
          .seekTo(Duration(seconds: controller.value.position.inSeconds + 10));
    }
    if (!controller.value.isPlaying) setState(() {});
  }

  void rewind() {
    if (controller.value.position.inSeconds > 10) {
      controller
          .seekTo(Duration(seconds: controller.value.position.inSeconds - 10));
    } else {
      controller.seekTo(Duration(seconds: 0));
    }
    if (!controller.value.isPlaying) setState(() {});
  }

  List<Widget> videoBuiltInChildrens() {
    return [
      Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              showSubtitles
                  ? Container(
                      decoration: BoxDecoration(
                          color: widget.subtitleStyle.background,
                          borderRadius: BorderRadius.circular(5)),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Text(
                          controller.value.initialized
                              ? subtitle != null ? subtitle.text : ""
                              : "",
                          style: TextStyle(
                            fontWeight: widget.subtitleStyle.fontweight,
                            color: widget.subtitleStyle.colors,
                            fontSize: widget.subtitleStyle.fontSize,
                          ),
                        ),
                      ),
                    )
                  : Container(),
              showMeau
                  ? Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.white38,
                            borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Row(
                            children: [
                              Text('$videoSeek/$videoDuration',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: VideoProgressIndicator(
                                  controller,
                                  allowScrubbing: true,
                                  colors: VideoProgressColors(
                                      playedColor:
                                          widget.videoStyle.playedColor),
                                  padding: const EdgeInsets.all(8.0),
                                ),
                              ),
                              GestureDetector(
                                  onTap: () {
                                    print("fullscreen test");
                                    try {
                                      toggleFullScreen();
                                    } catch (e) {
                                      print("fullscreen test $e");
                                    }
                                  },
                                  child: widget.videoStyle.fullscreen)
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
      showMeau
          ? Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    onTap: () {
                      rewind();
                    },
                    child: widget.videoStyle.backward,
                  ),
                  InkWell(
                    onTap: () {
                      togglePlay();
                    },
                    child: controller.value.isPlaying
                        ? widget.videoStyle.pause
                        : widget.videoStyle.play,
                  ),
                  InkWell(
                    onTap: () {
                      fastForward();
                    },
                    child: widget.videoStyle.forward,
                  ),
                ],
              ),
            )
          : Container(),
      showMeau == true
          ? Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 45,
                color: Colors.white10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 15.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            m3u8show = true;
                          });
                        },
                        child: Padding(
                            padding: EdgeInsets.all(5),
                            child: Container(
                                decoration: BoxDecoration(
                                    // color: Colors.white,
                                    borderRadius: BorderRadius.circular(5)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(m3u8quality,
                                      style: widget.videoStyle.qualitystyle),
                                ))),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(),
      m3u8show == true
          ? (offline == false)
              ? Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50.0, right: 5),
                    child: SingleChildScrollView(
                      child: Column(
                        children: m3u8List
                            .map((e) => InkWell(
                                  onTap: () {
                                    m3u8quality = e.dataquality;
                                    m3u8show = false;
                                    duration2 = controller.value.position;
                                    onselectquality(e);
                                  },
                                  child: Container(
                                      width: 90,
                                      color: Colors.white,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "${e.dataquality}",
                                          style: widget.videoStyle.qashowstyle,
                                        ),
                                      )),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                )
              : Align(
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.only(left: 15.0),
                          child: Icon(Icons.arrow_back),
                        ),
                      ),
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Offline",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
          : Container()
    ];
  }

  @override
  Widget build(BuildContext context) {
    final videoChildrens = <Widget>[
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
    videoChildrens.addAll(videoBuiltInChildrens());
    return AspectRatio(
      aspectRatio:
          fullscreen ? _calculateAspectRatio(context) : widget.aspectRatio,
      child: controller.value.initialized
          ? Stack(children: videoChildrens)
          : widget.videoLoadingStyle.loading,
    );
  }

  void videoControllSetup(String url) {
    videoInit(url);
    controller.addListener(listener);
    controller.play();
  }

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
      _subtitleWatcher(controller);
    }
  }

  _subtitleWatcher(VideoPlayerController videoPlayerController,
      {String sub}) async {
    Subtitles subtitles = await getSubtitles(sub);
    VideoPlayerValue latestValue = videoPlayerController.value;

    Duration videoPlayerPosition = latestValue.position;
    if (videoPlayerPosition != null) {
      subtitles.subtitles.forEach((Subtitle subtitleItem) {
        if (videoPlayerPosition.inMilliseconds >
                subtitleItem.startTime.inMilliseconds &&
            videoPlayerPosition.inMilliseconds <
                subtitleItem.endTime.inMilliseconds) {
          if (this.mounted) {
            setState(() {
              subtitle = subtitleItem;
            });
          }
        }
      });
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

  void m3u8clean() async {
    print(m3u8List.length);
    for (int i = 2; i < m3u8List.length; i++) {
      try {
        final Directory directory = await getApplicationDocumentsDirectory();
        final File file =
            File('${directory.path}/${m3u8List[i].dataquality}.m3u8');
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
      m3u8List.clear();
    } catch (e) {
      print("m3u8 video list clean error $e");
    }
  }

  @override
  void dispose() {
    controller.dispose();
    m3u8clean();
    showSubtitles = false;
    sublistener = false;
    super.dispose();
  }
}
