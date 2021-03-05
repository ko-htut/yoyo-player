import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:yoyo_player/src/source/cupertino_progress_bar.dart';
import 'package:yoyo_player/src/source/yoyo_progress_colors.dart';
import 'package:yoyo_player/src/utils/utils.dart';

import 'yoyo_controller.dart';

class CupertinoControls extends StatefulWidget {
  const CupertinoControls({
    required this.backgroundColor,
    required this.iconColor,
    Key? key,
  }) : super(key: key);

  final Color backgroundColor;
  final Color iconColor;

  @override
  State<StatefulWidget> createState() {
    return _CupertinoControlsState();
  }
}

class _CupertinoControlsState extends State<CupertinoControls>
    with SingleTickerProviderStateMixin {
  late VideoPlayerValue _latestValue;
  late double _latestVolume = 0.5;
  bool _hideStuff = true;
  Timer? _hideTimer;
  bool _hidenav = true;
  final marginSize = 5.0;
  late Timer _expandCollapseTimer;
  late Timer _initTimer;
  bool _dragging = false;
  bool _control = true;
  double _fontsize = 15;
  List<double> _fontsizelist = [13, 15, 17, 19, 21, 23, 25];
  int _subfontColor = 1;
  int indexsub = 0;
  bool _hidesubcolor = true;
  bool _ismute = false;
  List<Color> _subColors = [
    Colors.black,
    Colors.green,
    Colors.white,
    Colors.grey,
    Colors.blueGrey,
    Colors.yellow,
    Colors.amber,
    Colors.blue,
    Colors.red,
    Colors.lime,
    Colors.brown
  ];

  VideoPlayerController? controller;
  YoYoController? yoyoController;
  AnimationController? playPauseIconAnimationController;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // if (_latestValue.hasError) {
    //   return yoyoController!.errorBuilder != null
    //       ? yoyoController!.errorBuilder!(
    //           context,
    //           yoyoController!.videoPlayerController!.value.errorDescription!,
    //         )

    //   : const Center(
    //       child: Icon(
    //       CupertinoIcons.exclamationmark_circle,
    //       color: Colors.white,
    //       size: 42,
    //     ));

    //   return yoyoController!.errorBuilder != null
    //       ? yoyoController!.errorBuilder!(
    //           context,
    //           yoyoController!.videoPlayerController!.value.errorDescription!,
    //         )
    //       : const Center(
    //           child: Icon(
    //             CupertinoIcons.exclamationmark_circle,
    //             color: Colors.white,
    //             size: 42,
    //           ),
    //         );

    final backgroundColor = widget.backgroundColor;
    final iconColor = widget.iconColor;
    yoyoController = YoYoController.of(context);
    controller = yoyoController!.videoPlayerController;
    final orientation = MediaQuery.of(context).orientation;
    final barHeight = orientation == Orientation.portrait ? 30.0 : 47.0;
    final buttonPadding = orientation == Orientation.portrait ? 16.0 : 24.0;

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () {
          _cancelAndRestartTimer();
        },
        child: Stack(
          children: [
            AbsorbPointer(
              absorbing: _hideStuff,
              child: Column(
                children: <Widget>[
                  _buildTopBar(
                      backgroundColor, iconColor, barHeight, buttonPadding),
                  _buildHitArea(),
                  _buildBottomBar(backgroundColor, iconColor, barHeight),
                ],
              ),
            ),
            if (_hidenav == false)
              Align(
                  alignment: Alignment.topRight,
                  child: Listener(
                      child: _setting(backgroundColor, iconColor, barHeight))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller!.removeListener(_updateState);
    _hideTimer!.cancel();
    _expandCollapseTimer.cancel();
    _initTimer.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = yoyoController;
    yoyoController = YoYoController.of(context);
    controller = yoyoController!.videoPlayerController;

    playPauseIconAnimationController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 400),
    );

    if (_oldController != yoyoController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  AnimatedOpacity _buildBottomBar(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
  ) {
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.bottomCenter,
        margin: EdgeInsets.all(marginSize),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: 10.0,
              sigmaY: 10.0,
            ),
            child: Container(
              height: barHeight,
              color: backgroundColor,
              child: yoyoController!.isLive
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        _buildPlayPause(controller!, iconColor, barHeight),
                        _buildLive(iconColor),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        _buildPlayPause(controller!, iconColor, barHeight),
                        _buildPosition(iconColor),
                        _buildProgressBar(),
                        _buildRemaining(iconColor),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _setting(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
  ) {
    //
    return Container(
      color: Colors.grey,
      width: MediaQuery.of(context).size.width - 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Setting"),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _hidenav = true;
                              });
                            },
                            child: Icon(Icons.close),
                          )
                        ],
                      ),
                    ),
                    Divider(
                      color: Colors.white,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.settings,
                          ),
                          Text("Brightness")
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 5.0,
                        right: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.fullscreen,
                              ),
                              Text("Fullscreen")
                            ],
                          ),
                          Switch(
                            inactiveTrackColor: Colors.white,
                            inactiveThumbColor: Colors.red,
                            activeTrackColor: Colors.white,
                            value: yoyoController!.isFullScreen,
                            onChanged: (value) {
                              //
                              setState(() {
                                _hideStuff = value;

                                yoyoController!.toggleFullScreen();
                                _expandCollapseTimer = Timer(
                                    const Duration(milliseconds: 300), () {
                                  setState(() {
                                    _cancelAndRestartTimer();
                                  });
                                });
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 5.0,
                        right: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.volume_mute,
                              ),
                              Text("Mute")
                            ],
                          ),
                          Switch(
                            inactiveTrackColor: Colors.white,
                            inactiveThumbColor: Colors.red,
                            activeTrackColor: Colors.white,
                            value: _ismute,
                            onChanged: (value) {
                              setState(() {
                                if (_latestValue.volume > 0) {
                                  _ismute = true;
                                } else {
                                  _ismute = false;
                                }
                                _cancelAndRestartTimer();

                                if (_latestValue.volume == 0) {
                                  controller!.setVolume(_latestVolume);
                                } else {
                                  _latestVolume = controller!.value.volume;
                                  controller!.setVolume(0.0);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Playback speed"),
                Divider(
                  color: Colors.white,
                ),
                Container(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: yoyoController!.playbackSpeeds
                        .map(
                          (e) => GestureDetector(
                            onTap: () {
                              setState(() {
                                controller!.setPlaybackSpeed(e);
                              });
                            },
                            child: Container(
                                margin: EdgeInsets.all(2.0),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: (_latestValue.playbackSpeed == e)
                                        ? Colors.red[200]
                                        : Colors.transparent),
                                child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Center(
                                    child: Text(
                                      e.toString(),
                                    ),
                                  ),
                                )),
                          ),
                        )
                        .toList(),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLive(Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        'LIVE',
        style: TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  Expanded _buildHitArea() {
    final bool isFinished = _latestValue.duration != null &&
        _latestValue.position >= _latestValue.duration;

    return Expanded(
      child: GestureDetector(
          onTap: _latestValue != null && _latestValue.isPlaying
              ? _cancelAndRestartTimer
              : () {
                  _hideTimer!.cancel();

                  setState(() {
                    _hideStuff = false;
                  });
                },
          child: controller!.value.isInitialized
              ? Container(
                  color: Colors.transparent,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity:
                          !_latestValue.isPlaying && !_dragging ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: _buildSkipBack(Colors.white, 50)),
                          GestureDetector(
                            child: Container(
                              decoration: BoxDecoration(
                                color: widget.backgroundColor,
                                borderRadius: BorderRadius.circular(48.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: IconButton(
                                    icon: isFinished
                                        ? Icon(Icons.replay,
                                            size: 32.0, color: widget.iconColor)
                                        : AnimatedIcon(
                                            icon: AnimatedIcons.play_pause,
                                            progress:
                                                playPauseIconAnimationController!,
                                            size: 32.0,
                                            color: widget.iconColor),
                                    onPressed: () {
                                      _playPause();
                                    }),
                              ),
                            ),
                          ),
                          Expanded(child: _buildSkipForward(Colors.white, 50)),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              new AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Loading...',
                          style: TextStyle(color: Colors.blue),
                        )
                      ],
                    ),
                  ),
                )),
    );
  }

  Widget _buildMenubutton(
    VideoPlayerController controller,
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: () {
        //
        _cancelAndRestartTimer();
        setState(() {
          if (_hidenav == true) {
            _hidenav = false;
          } else {
            _hidenav = true;
          }
        });
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0),
            child: Container(
              color: backgroundColor,
              child: Container(
                height: barHeight,
                padding: EdgeInsets.only(
                  left: buttonPadding,
                  right: buttonPadding,
                ),
                child: Icon(
                  Icons.menu,
                  color: iconColor,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(
    VideoPlayerController controller,
    Color iconColor,
    double barHeight,
  ) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 6.0,
        ),
        child: Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position =
        _latestValue != null ? _latestValue.position : const Duration();

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        formatDuration(position),
        style: TextStyle(
          color: iconColor,
          fontSize: 12.0,
        ),
      ),
    );
  }

  Widget _buildRemaining(Color iconColor) {
    final position = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration - _latestValue.position
        : const Duration();

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Text(
        '-${formatDuration(position)}',
        style: TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  GestureDetector _buildSkipBack(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: _skipBack,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(left: 10.0),
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 6.0,
        ),
        child: Icon(
          CupertinoIcons.gobackward_15,
          color: iconColor,
          size: 18.0,
        ),
      ),
    );
  }

  GestureDetector _buildSkipForward(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: _skipForward,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 8.0,
        ),
        margin: const EdgeInsets.only(
          right: 8.0,
        ),
        child: Icon(
          CupertinoIcons.goforward_15,
          color: iconColor,
          size: 18.0,
        ),
      ),
    );
  }

  Widget _buildTopBar(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return Container(
      height: barHeight,
      margin: EdgeInsets.only(
        top: marginSize,
        right: marginSize,
        left: marginSize,
      ),
      child: Row(
        children: <Widget>[
          const Spacer(),
          _buildMenubutton(
              controller!, backgroundColor, iconColor, barHeight, buttonPadding)
        ],
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer!.cancel();

    setState(() {
      _hideStuff = false;
      _startHideTimer();
    });
  }

  Future<void> _initialize() async {
    controller!.addListener(_updateState);

    _updateState();

    if ((controller!.value != null && controller!.value.isPlaying) ||
        yoyoController!.autoPlay) {
      _startHideTimer();
    }

    if (yoyoController!.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      yoyoController!.toggleFullScreen();
      _expandCollapseTimer = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: CupertinoVideoProgressBar(
          controller!,
          onDragStart: () {
            setState(() {
              _dragging = true;
            });

            _hideTimer!.cancel();
          },
          onDragEnd: () {
            setState(() {
              _dragging = false;
            });

            _startHideTimer();
          },
          colors: yoyoController!.cupertinoProgressColors ??
              YoYoProgressColors(
                playedColor: const Color.fromARGB(
                  120,
                  255,
                  255,
                  255,
                ),
                handleColor: const Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ),
                bufferedColor: const Color.fromARGB(
                  60,
                  255,
                  255,
                  255,
                ),
                backgroundColor: const Color.fromARGB(
                  20,
                  255,
                  255,
                  255,
                ),
              ),
        ),
      ),
    );
  }

  void _playPause() {
    bool isFinished;
    if (_latestValue.duration != null) {
      isFinished = _latestValue.position >= _latestValue.duration;
    } else {
      isFinished = false;
    }

    setState(() {
      if (controller!.value.isPlaying) {
        _hideStuff = false;
        _hideTimer!.cancel();
        controller!.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller!.value.isInitialized) {
          controller!.initialize().then((_) {
            controller!.play();
          });
        } else {
          if (isFinished) {
            controller!.seekTo(const Duration());
          }
          controller!.play();
        }
      }
    });
  }

  void _skipBack() {
    _cancelAndRestartTimer();
    final beginning = const Duration().inMilliseconds;
    final skip =
        (_latestValue.position - const Duration(seconds: 15)).inMilliseconds;
    controller!.seekTo(Duration(milliseconds: math.max(skip, beginning)));
  }

  void _skipForward() {
    _cancelAndRestartTimer();
    final end = _latestValue.duration.inMilliseconds;
    final skip =
        (_latestValue.position + const Duration(seconds: 15)).inMilliseconds;
    controller!.seekTo(Duration(milliseconds: math.min(skip, end)));
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    if (!mounted) return;
    setState(() {
      _latestValue = controller!.value;
    });
  }
}
