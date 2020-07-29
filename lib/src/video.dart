import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock/wakelock.dart';
import 'model/audio.dart';
import 'model/m3u8.dart';
import 'model/m3u8s.dart';

class YoYoPlayer extends StatefulWidget {
  final String url;

  /// yoyo_player is a video player that allows you to select HLS video streaming by selecting the quality
  YoYoPlayer(this.url, {Key key}) : super(key: key);

  @override
  _YoYoPlayerState createState() => _YoYoPlayerState();
}

class _YoYoPlayerState extends State<YoYoPlayer> {
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
  String m3u8quality = "Auto";

  @override
  void initState() {
    super.initState();
    initPlayer();
    m3u8video();
  }

  void initPlayer() {
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

  Future<M3U8s> m3u8video() async {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        controller.value.initialized
            ? GestureDetector(child: VideoPlayer(controller))
            : AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              new AlwaysStoppedAnimation<Color>(Colors.amber),
                        ),
                        SizedBox(height: 5),
                        Text('Loading...')
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
