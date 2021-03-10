// Project imports:
import 'package:yoyo_player/src/configuration/yoyo_player_configuration.dart';
import 'package:yoyo_player/src/configuration/yoyo_player_data_source.dart';
import 'package:yoyo_player/src/core/yoyo_player.dart';
import 'package:yoyo_player/src/core/yoyo_player_controller.dart';
import 'package:yoyo_player/src/core/yoyo_player_utils.dart';
import 'package:yoyo_player/src/playlist/yoyo_player_playlist_configuration.dart';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:yoyo_player/src/playlist/better_player_playlist_controller.dart';

///Special version of Better Player used to play videos in playlist.
class YoYoPlayerPlaylist extends StatefulWidget {
  final List<YoYoPlayerDataSource> yoyoPlayerDataSourceList;
  final YoYoPlayerConfiguration yoyoPlayerConfiguration;
  final YoYoPlayerPlaylistConfiguration yoyoPlayerPlaylistConfiguration;

  const YoYoPlayerPlaylist({
    Key? key,
    required this.yoyoPlayerDataSourceList,
    required this.yoyoPlayerConfiguration,
    required this.yoyoPlayerPlaylistConfiguration,
  }) : super(key: key);

  @override
  YoYoPlayerPlaylistState createState() => YoYoPlayerPlaylistState();
}

///State of BetterPlayerPlaylist, used to access BetterPlayerPlaylistController.
class YoYoPlayerPlaylistState extends State<YoYoPlayerPlaylist> {
  YoYoPlayerPlaylistController? _yoyoPlayerPlaylistController;

  YoYoPlayerController? get _yoyoPlayerController =>
      _yoyoPlayerPlaylistController!.yoyoPlayerController;

  ///Get BetterPlayerPlaylistController
  YoYoPlayerPlaylistController? get betterPlayerPlaylistController =>
      _yoyoPlayerPlaylistController;

  @override
  void initState() {
    _yoyoPlayerPlaylistController = YoYoPlayerPlaylistController(
        widget.yoyoPlayerDataSourceList,
        yoyoPlayerConfiguration: widget.yoyoPlayerConfiguration,
        yoyoPlayerPlaylistConfiguration:
            widget.yoyoPlayerPlaylistConfiguration);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _yoyoPlayerController!.getAspectRatio() ??
          YoYoPlayerUtils.calculateAspectRatio(context),
      child: YoYoPlayer(
        controller: _yoyoPlayerController!,
      ),
    );
  }

  @override
  void dispose() {
    _yoyoPlayerPlaylistController!.dispose();
    super.dispose();
  }
}
