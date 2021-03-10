// Flutter imports:
// Project imports:
import 'package:flutter/material.dart';
import 'package:yoyo_player/src/core/yoyo_player_utils.dart';
import 'package:yoyo_player/yoyo_player.dart';

///Special version of YoYo Player which is used to play video in list view.
class YoYoPlayerListVideoPlayer extends StatefulWidget {
  ///Video to show
  final YoYoPlayerDataSource dataSource;

  ///Video player configuration
  final YoYoPlayerConfiguration configuration;

  ///Fraction of the screen height that will trigger play/pause. For example
  ///if playFraction is 0.6 video will be played if 60% of player height is
  ///visible.
  final double playFraction;

  ///Flag to determine if video should be auto played
  final bool autoPlay;

  ///Flag to determine if video should be auto paused
  final bool autoPause;

  final YoYoPlayerListVideoPlayerController?
      yoyoPlayerListVideoPlayerController;

  const YoYoPlayerListVideoPlayer(
    this.dataSource, {
    this.configuration = const YoYoPlayerConfiguration(),
    this.playFraction = 0.6,
    this.autoPlay = true,
    this.autoPause = true,
    this.yoyoPlayerListVideoPlayerController,
    Key? key,
  })  : assert(playFraction >= 0.0 && playFraction <= 1.0,
            "Play fraction can't be null and must be between 0.0 and 1.0"),
        super(key: key);

  @override
  _YoYoPlayerListVideoPlayerState createState() =>
      _YoYoPlayerListVideoPlayerState();
}

class _YoYoPlayerListVideoPlayerState extends State<YoYoPlayerListVideoPlayer>
    with AutomaticKeepAliveClientMixin<YoYoPlayerListVideoPlayer> {
  YoYoPlayerController? _yoyoPlayerController;
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    _yoyoPlayerController = YoYoPlayerController(
      widget.configuration.copyWith(
        playerVisibilityChangedBehavior: onVisibilityChanged,
      ),
      yoyoPlayerDataSource: widget.dataSource,
      yoyoPlayerPlaylistConfiguration: const YoYoPlayerPlaylistConfiguration(),
    );

    if (widget.yoyoPlayerListVideoPlayerController != null) {
      widget.yoyoPlayerListVideoPlayerController!
          .setBetterPlayerController(_yoyoPlayerController);
    }
  }

  @override
  void dispose() {
    _yoyoPlayerController!.dispose();
    _isDisposing = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AspectRatio(
      aspectRatio: _yoyoPlayerController!.getAspectRatio() ??
          YoYoPlayerUtils.calculateAspectRatio(context),
      child: YoYoPlayer(
        key: Key("${_getUniqueKey()}_player"),
        controller: _yoyoPlayerController!,
      ),
    );
  }

  void onVisibilityChanged(double visibleFraction) async {
    final bool? isPlaying = _yoyoPlayerController!.isPlaying();
    final bool? initialized = _yoyoPlayerController!.isVideoInitialized();
    if (visibleFraction >= widget.playFraction) {
      if (widget.autoPlay && initialized! && !isPlaying! && !_isDisposing) {
        _yoyoPlayerController!.play();
      }
    } else {
      if (widget.autoPause && initialized! && isPlaying! && !_isDisposing) {
        _yoyoPlayerController!.pause();
      }
    }
  }

  String _getUniqueKey() => widget.dataSource.hashCode.toString();

  @override
  bool get wantKeepAlive => true;
}
