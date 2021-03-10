// Dart imports:
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:yoyo_player/src/configuration/yoyo_player_controller_event.dart';
import 'package:yoyo_player/src/controls/yoyo_player_cupertino_controls.dart';
import 'package:yoyo_player/src/controls/yoyo_player_material_controls.dart';
import 'package:yoyo_player/src/subtitles/yoyo_player_subtitles_drawer.dart';
import 'package:yoyo_player/src/video_player/video_player.dart';

import '../../yoyo_player.dart';
import 'yoyo_player_utils.dart';

class YoYoPlayerWithControls extends StatefulWidget {
  final YoYoPlayerController? controller;

  const YoYoPlayerWithControls({Key? key, this.controller}) : super(key: key);

  @override
  _YoYoPlayerWithControlsState createState() => _YoYoPlayerWithControlsState();
}

class _YoYoPlayerWithControlsState extends State<YoYoPlayerWithControls> {
  YoYoPlayerSubtitlesConfiguration get subtitlesConfiguration =>
      widget.controller!.yoyoPlayerConfiguration.subtitlesConfiguration;

  YoYoPlayerControlsConfiguration get controlsConfiguration =>
      widget.controller!.yoyoPlayerConfiguration.controlsConfiguration;

  final StreamController<bool> playerVisibilityStreamController =
      StreamController();

  bool _initialized = false;

  StreamSubscription? _controllerEventSubscription;

  @override
  void initState() {
    playerVisibilityStreamController.add(true);
    _controllerEventSubscription =
        widget.controller!.controllerEventStream.listen(_onControllerChanged);
    super.initState();
  }

  @override
  void didUpdateWidget(YoYoPlayerWithControls oldWidget) {
    if (oldWidget.controller != widget.controller) {
      _controllerEventSubscription?.cancel();
      _controllerEventSubscription =
          widget.controller!.controllerEventStream.listen(_onControllerChanged);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    playerVisibilityStreamController.close();
    _controllerEventSubscription?.cancel();
    super.dispose();
  }

  void _onControllerChanged(YoYoPlayerControllerEvent event) {
    setState(() {
      if (!_initialized) {
        _initialized = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final YoYoPlayerController yoyoPlayerController =
        YoYoPlayerController.of(context);

    double? aspectRatio;
    if (yoyoPlayerController.isFullScreen) {
      if (yoyoPlayerController
          .yoyoPlayerConfiguration.autoDetectFullscreenDeviceOrientation) {
        aspectRatio =
            yoyoPlayerController.videoPlayerController?.value.aspectRatio ??
                1.0;
      } else {
        aspectRatio = yoyoPlayerController
                .yoyoPlayerConfiguration.fullScreenAspectRatio ??
            YoYoPlayerUtils.calculateAspectRatio(context);
      }
    } else {
      aspectRatio = yoyoPlayerController.getAspectRatio();
    }

    aspectRatio ??= 16 / 9;

    return Center(
      child: Container(
        width: double.infinity,
        color: yoyoPlayerController
            .yoyoPlayerConfiguration.controlsConfiguration.backgroundColor,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: _buildPlayerWithControls(yoyoPlayerController, context),
        ),
      ),
    );
  }

  Container _buildPlayerWithControls(
      YoYoPlayerController yoyoPlayerController, BuildContext context) {
    final configuration = yoyoPlayerController.yoyoPlayerConfiguration;
    var rotation = configuration.rotation;

    if (!(rotation <= 360 && rotation % 90 == 0)) {
      YoYoPlayerUtils.log("Invalid rotation provided. Using rotation = 0");
      rotation = 0;
    }
    if (yoyoPlayerController.yoyoPlayerDataSource == null) {
      return Container();
    }
    _initialized = true;

    final bool placeholderOnTop =
        yoyoPlayerController.yoyoPlayerConfiguration.placeholderOnTop;
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          if (placeholderOnTop) _buildPlaceholder(yoyoPlayerController),
          Transform.rotate(
            angle: rotation * pi / 180,
            child: _YoYoPlayerVideoFitWidget(
              yoyoPlayerController,
              yoyoPlayerController.yoyoPlayerConfiguration.fit,
            ),
          ),
          yoyoPlayerController.yoyoPlayerConfiguration.overlay ?? Container(),
          YoYoPlayerSubtitlesDrawer(
            yoyoPlayerController: yoyoPlayerController,
            yoyoPlayerSubtitlesConfiguration: subtitlesConfiguration,
            subtitles: yoyoPlayerController.subtitlesLines,
            playerVisibilityStream: playerVisibilityStreamController.stream,
          ),
          if (!placeholderOnTop) _buildPlaceholder(yoyoPlayerController),
          _buildControls(context, yoyoPlayerController),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(YoYoPlayerController yoyoPlayerController) {
    return yoyoPlayerController.yoyoPlayerDataSource!.placeholder ??
        yoyoPlayerController.yoyoPlayerConfiguration.placeholder ??
        Container();
  }

  Widget _buildControls(
    BuildContext context,
    YoYoPlayerController yoyoPlayerController,
  ) {
    if (controlsConfiguration.showControls) {
      YoYoPlayerTheme? playerTheme = controlsConfiguration.playerTheme;
      if (playerTheme == null) {
        if (Platform.isAndroid) {
          playerTheme = YoYoPlayerTheme.material;
        } else {
          playerTheme = YoYoPlayerTheme.cupertino;
        }
      }

      if (controlsConfiguration.customControlsBuilder != null &&
          playerTheme == YoYoPlayerTheme.custom) {
        return controlsConfiguration
            .customControlsBuilder!(yoyoPlayerController);
      } else if (playerTheme == YoYoPlayerTheme.material) {
        return _buildMaterialControl();
      } else if (playerTheme == YoYoPlayerTheme.cupertino) {
        return _buildCupertinoControl();
      }
    }

    return const SizedBox();
  }

  Widget _buildMaterialControl() {
    return YoYoPlayerMaterialControls(
      onControlsVisibilityChanged: onControlsVisibilityChanged,
      controlsConfiguration: controlsConfiguration,
    );
  }

  Widget _buildCupertinoControl() {
    return YoYoPlayerCupertinoControls(
      onControlsVisibilityChanged: onControlsVisibilityChanged,
      controlsConfiguration: controlsConfiguration,
    );
  }

  void onControlsVisibilityChanged(bool state) {
    playerVisibilityStreamController.add(state);
  }
}

///Widget used to set the proper box fit of the video. Default fit is 'fill'.
class _YoYoPlayerVideoFitWidget extends StatefulWidget {
  const _YoYoPlayerVideoFitWidget(
    this.yoyoPlayerController,
    this.boxFit, {
    Key? key,
  }) : super(key: key);

  final YoYoPlayerController yoyoPlayerController;
  final BoxFit boxFit;

  @override
  _YoYoPlayerVideoFitWidgetState createState() =>
      _YoYoPlayerVideoFitWidgetState();
}

class _YoYoPlayerVideoFitWidgetState extends State<_YoYoPlayerVideoFitWidget> {
  VideoPlayerController? get controller =>
      widget.yoyoPlayerController.videoPlayerController;

  bool _initialized = false;

  VoidCallback? _initializedListener;

  bool _started = false;

  StreamSubscription? _controllerEventSubscription;

  @override
  void initState() {
    super.initState();
    if (!widget.yoyoPlayerController.yoyoPlayerConfiguration
        .showPlaceholderUntilPlay) {
      _started = true;
    } else {
      _started = widget.yoyoPlayerController.hasCurrentDataSourceStarted;
    }

    _initialize();
  }

  @override
  void didUpdateWidget(_YoYoPlayerVideoFitWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.yoyoPlayerController.videoPlayerController != controller) {
      if (_initializedListener != null) {
        oldWidget.yoyoPlayerController.videoPlayerController!
            .removeListener(_initializedListener!);
      }
      _initialized = false;
      _initialize();
    }
  }

  void _initialize() {
    if (controller?.value.initialized == false) {
      _initializedListener = () {
        if (!mounted) {
          return;
        }

        if (_initialized != controller!.value.initialized) {
          _initialized = controller!.value.initialized;
          setState(() {});
        }
      };
      controller!.addListener(_initializedListener!);
    } else {
      _initialized = true;
    }

    _controllerEventSubscription =
        widget.yoyoPlayerController.controllerEventStream.listen((event) {
      if (event == YoYoPlayerControllerEvent.play) {
        if (!_started) {
          setState(() {
            _started = widget.yoyoPlayerController.hasCurrentDataSourceStarted;
          });
        }
      }
      if (event == YoYoPlayerControllerEvent.setupDataSource) {
        setState(() {
          _started = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized && _started) {
      return Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: FittedBox(
            fit: widget.boxFit,
            child: SizedBox(
              width: controller!.value.size?.width ?? 0,
              height: controller!.value.size?.height ?? 0,
              child: VideoPlayer(controller),
              //
            ),
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  void dispose() {
    if (_initializedListener != null) {
      widget.yoyoPlayerController.videoPlayerController!
          .removeListener(_initializedListener!);
    }
    _controllerEventSubscription?.cancel();
    super.dispose();
  }
}
