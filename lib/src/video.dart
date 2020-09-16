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
  //Current ScreenSize
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
      aspectRatio: fullscreen
          ? calculateAspectRatio(context, screenSize)
          : widget.aspectRatio,
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
            topchip(
              Text(m3u8quality + ":$_playtype",
                  style: widget.videoStyle.qualitystyle),
              () {
                // quality function
                m3u8show = true;
              },
            ),
            Container(
              width: 5,
            ),
            Icon(
              Icons.fullscreen,
              color: Colors.white,
            ),
            Container(
              width: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget subtitleShow() {
    return Text("subtitle");
  }

  Widget m3u8list() {
    return m3u8show == true
        ? Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0, right: 5),
              child: SingleChildScrollView(
                child: Column(
                  children: m3u8List
                      .map((e) => InkWell(
                            onTap: () {
                              m3u8quality = e.dataquality;
                              m3u8show = false;
                              duration2 = controller.value.position;
                              // onselectquality(e);
                            },
                            child: Container(
                                width: 90,
                                color: Colors.grey,
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
        : Container();
  }

  List<Widget> videoBuiltInChildrens() {
    return [
      actionBar(),
      subtitleShow(),
      bottomBar(controller, "$videoSeek", "$videoDuration"),
      m3u8list()
    ];
  }

  void urlcheck(String url) {
    final netRegx = new RegExp(r'^(http|https):\/\/([\w.]+\/?)\S*');
    final isNetwork = netRegx.hasMatch(url);
    if (isNetwork) {
      setState(() {
        offline = false;
      });
      if (url.endsWith("mkv")) {
        if (widget.onpeningvideo != null) {
          setState(() {
            _playtype = "MKV";
          });
          widget.onpeningvideo("MKV");
        }
        videoControllSetup(url);
      } else if (url.endsWith("mp4")) {
        if (widget.onpeningvideo != null) {
          setState(() {
            _playtype = "MP4";
          });
          widget.onpeningvideo("MP4");
        }
        videoControllSetup(url);
      } else if (url.endsWith("m3u8")) {
        if (widget.onpeningvideo != null) {
          setState(() {
            _playtype = "HLS";
          });
          widget.onpeningvideo("M3U8");
        }
        setState(() {
          _playtype = "source";
        });
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
    print("---- m3u8 fesh start ----\n"
        "fet new data form $video data start");
    m3u8video(video);
  }

  Future<M3U8s> m3u8video(String video) async {
    m3u8List.add(M3U8pass(dataquality: "Auto", dataurl: video));
    RegExp regExpAudio = new RegExp(
      r"""^#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="(.*)",NAME="(.*)",AUTOSELECT=(.*),DEFAULT=(.*),CHANNELS="(.*)",URI="(.*)""",
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
          print("old m3u8Content : $m3u8Content");
          m3u8Content = null;
        }
      },
    );
    if (m3u8Content == null && video != null) {
      http.Response response = await http.get(video);
      if (response.statusCode == 200) {
        m3u8Content = utf8.decode(response.bodyBytes);
      }
    }
    print("m3u8Content : $m3u8Content");
    List<RegExpMatch> matches = regExp.allMatches(m3u8Content).toList();
    List<RegExpMatch> audioMatches =
        regExpAudio.allMatches(m3u8Content).toList();
    print("print m3u8 list : ${m3u8List.length}");

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
        audioMatches.forEach(
          (RegExpMatch regExpMatch2) async {
            String audiourl = (regExpMatch2.group(1)).toString();
            // audioList.add(AUDIO(url: audiourl));
            final isNetwork = netRegx.hasMatch(audiourl);
            final match = netRegx2.firstMatch(video);
            String auurl = audiourl;
            if (isNetwork) {
              auurl = audiourl;
            } else {
              print(match);
              final audataurl = match.group(0);
              auurl = "$audataurl$audiourl";
              print("url network audio  $url $audiourl");
            }
            audioList.add(AUDIO(url: auurl));
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

    print(m3u8List);
    M3U8s m3u8s = M3U8s(m3u8s: m3u8List);
    print("m3u8s");
    return m3u8s;
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
}
