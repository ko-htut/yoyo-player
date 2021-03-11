import 'package:flutter/material.dart';
import 'package:yoyo_player/yoyo_player.dart';

class PlayPage extends StatefulWidget {
  PlayPage({Key? key}) : super(key: key);

  @override
  _PlayPageState createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  late YoYoPlayerController _yoyoPlayerController;

  @override
  void initState() {
    YoYoPlayerConfiguration betterPlayerConfiguration = YoYoPlayerConfiguration(
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
    );
    YoYoPlayerDataSource dataSource = YoYoPlayerDataSource(
        YoYoPlayerDataSourceType.network,
        "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8",
        useHlsSubtitles: true);
    _yoyoPlayerController = YoYoPlayerController(betterPlayerConfiguration);
    _yoyoPlayerController.setupDataSource(dataSource);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HLS subtitles"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Player with HLS stream which loads subtitles from HLS."
              " You can choose subtitles by using overflow menu (3 dots in right corner).",
              style: TextStyle(fontSize: 16),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: YoYoPlayer(controller: _yoyoPlayerController),
          ),
        ],
      ),
    );
  }
}
