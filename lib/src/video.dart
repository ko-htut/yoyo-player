import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orientation/orientation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock/wakelock.dart';
import 'package:yoyo_player/src/video_icon_style.dart';
import 'model/audio.dart';
import 'model/m3u8.dart';
import 'model/m3u8s.dart';

class YoYoPlayer extends StatefulWidget {
  ///Video resource
  final String url;
  final bool deafultfullscreen;
  final bool multipleaudioquality;

  /// Video Player Icon style
  final VideoIconStyle videoIconStyle;
  final double aspectRatio;

  /// yoyo_player is a video player that allows you to select HLS video streaming by selecting the quality
  YoYoPlayer({
    Key key,
    @required this.url,
    @required this.deafultfullscreen,
    @required this.multipleaudioquality,
    @required this.aspectRatio,
    this.videoIconStyle,
  }) : super(key: key);

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
  List<M3U8> m3u8List = List();
  List<AUDIO> audioList = List();
  String m3u8Content;
  bool m3u8show = false;
  bool fullscreen = false;
  bool showMeau = false;
  String m3u8quality = "Auto";
  Timer showTime;
  Size get screenSize => MediaQuery.of(context).size;
  @override
  void initState() {
    super.initState();
    videoControllSetup(widget.url);
    getm3u8(widget.url);
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
            if (widget.deafultfullscreen != null) {
              // widget.onfullscreen(fullscreen);
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

  void getm3u8(String video) {
    if (m3u8List.length > 0) {
      print("${m3u8List.length} : data start clean");
      m3u8clean();
    }
    print("fet new data form $video data start");
    m3u8video(video);
  }

  Future<M3U8s> m3u8video(String video) async {
    m3u8List.add(M3U8(quality: "Auto", url: widget.url));

    RegExp regExpaudio = new RegExp(
      r"""^#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="(.*)",NAME="(.*)",AUTOSELECT=(.*),DEFAULT=(.*),CHANNELS="(.*)",URI="(.*)""",
      caseSensitive: false,
      multiLine: true,
    );

    RegExp regExp = new RegExp(
      r"#EXT-X-STREAM-INF:(?:.*,RESOLUTION=(\d+x\d+))?,?(.*)\r?\n(.*)",
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
        String url = (regExpMatch.group(3)).toString();

        audiomatches.forEach(
          (RegExpMatch regExpMatch2) async {
            String audiourl = (regExpMatch2.group(6)).toString();
            audioList.add(AUDIO(url: audiourl));
          },
        );
        print("Audio list last : ${audioList.last.url}");
        audioList.last;
        String audio = audioList.last.url;
        try {
          final Directory directory = await getApplicationDocumentsDirectory();
          final File file = File('${directory.path}/$quality.m3u8');
          await file.writeAsString(
              """#EXTM3U\n#EXT-X-INDEPENDENT-SEGMENTS\n#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-medium",NAME="audio",AUTOSELECT=YES,DEFAULT=YES,CHANNELS="2",URI="$audio"\n#EXT-X-STREAM-INF:CLOSED-CAPTIONS=NONE,BANDWIDTH=1469712,RESOLUTION=$quality,FRAME-RATE=30.000\n$url """);
        } catch (e) {
          print("Couldn't write file");
        }
        m3u8List.add(M3U8(quality: quality, url: url));
      },
    );
    M3U8s m3u8s = M3U8s(m3u8s: m3u8List);
    return m3u8s;
  }

  void onselectquality(M3U8 data) async {
    controller.value.isPlaying ? controller.pause() : controller.pause();
    if (data.quality == " . Auto") {
      videoControllSetup(data.url);
    } else {
      try {
        String text;
        final Directory directory = await getApplicationDocumentsDirectory();
        final File file = File('${directory.path}/${data.quality}.m3u8');
        print("read file success");
        text = await file.readAsString();
        print("data : $text");
        localm3u8play(file);
        // videoControllSetup(file);
      } catch (e) {
        print("Couldn't read file ${data.quality} e: $e");
      }
      print("data : ${data.quality}");
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
      showMeau
          ? Padding(
              padding: const EdgeInsets.all(5.0),
              child: Align(
                alignment: Alignment.bottomCenter,
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
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: VideoProgressIndicator(
                            controller,
                            allowScrubbing: true,
                            colors:
                                VideoProgressColors(playedColor: Colors.amber),
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
                            child: Icon(widget.videoIconStyle.fullscreen,
                                color: Colors.white))
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Container(),
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
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.yellow[100],
                          borderRadius: BorderRadius.circular(50)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(widget.videoIconStyle.backward),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      togglePlay();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.yellow[100],
                          borderRadius: BorderRadius.circular(50)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(controller.value.isPlaying
                            ? widget.videoIconStyle.pause
                            : widget.videoIconStyle.play),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      fastForward();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.yellow[100],
                          borderRadius: BorderRadius.circular(50)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(widget.videoIconStyle.forward),
                      ),
                    ),
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
                                  child: Text(
                                    m3u8quality,
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ))),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(),
      m3u8show == true
          ? Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 50.0, right: 5),
                child: Column(
                  children: m3u8List
                      .map((e) => InkWell(
                            onTap: () {
                              m3u8quality = e.quality;
                              m3u8show = false;
                              duration2 = controller.value.position;
                              onselectquality(e);
                            },
                            child: Container(
                                width: 90,
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text("${e.quality}"),
                                )),
                          ))
                      .toList(),
                ),
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
          : Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          new AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                    SizedBox(height: 10),
                    Text('Loading...')
                  ],
                ),
              ),
            ),
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
  }

  void videoInit(String url) {
    controller = VideoPlayerController.network(url, formatHint: VideoFormat.hls)
      ..initialize()
          .then((_) => setState(() => hasInitError = false))
          .catchError((e) => setState(() => hasInitError = true));
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
        final File file = File('${directory.path}/${m3u8List[i].quality}.m3u8');
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
    super.dispose();
  }
}
