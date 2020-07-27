import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
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
  //m3u8 data video list
  List<M3U8> m3u8List = List();
  String m3u8Content;

  @override
  void initState() {
    super.initState();
    initPlayer();
    m3u8video();
  }

  void initPlayer() {}

  Future<M3U8s> m3u8video() async {
    m3u8List.add(M3U8(quality: "Auto", url: widget.url));
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
    matches.forEach((RegExpMatch regExpMatch) {
      String quality = (regExpMatch.group(1)).toString();
      String url = (regExpMatch.group(3)).toString();
      final fullurl = new RegExp(r'^(http|https):\/\/([\w.]+\/?)\S*');
      final isfullurl = fullurl.hasMatch(url);
      String vdurl;
      if (isfullurl) {
        vdurl = url;
      } else {
        // vdurl = "$url";
      }
      m3u8List.add(M3U8(quality: quality, url: vdurl));
    });
    M3U8s m3u8s = M3U8s(m3u8s: m3u8List);
    return m3u8s;
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayer(controller);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
