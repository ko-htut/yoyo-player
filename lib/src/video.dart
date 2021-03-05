import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock/wakelock.dart';

import 'controller/player_with_controls.dart';
import 'controller/yoyo_controller.dart';

class YoYoPlayer extends StatefulWidget {
  const YoYoPlayer({
    Key? key,
    required this.controller,
  })   : assert(controller != null, 'You must provide a yoyo controller'),
        super(key: key);

  final YoYoController controller;

  @override
  YoYoState createState() {
    return YoYoState();
  }
}

class YoYoState extends State<YoYoPlayer> {
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);
    super.dispose();
  }

  @override
  void didUpdateWidget(YoYoPlayer oldWidget) {
    if (oldWidget.controller != widget.controller) {
      widget.controller.addListener(listener);
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> listener() async {
    if (widget.controller.isFullScreen && !_isFullScreen) {
      _isFullScreen = true;
      await _pushFullScreenWidget(context);
    } else if (_isFullScreen) {
      Navigator.of(context, rootNavigator: true).pop();
      _isFullScreen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoYoControllerProvider(
      controller: widget.controller,
      child: const PlayerWithControls(),
    );
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final controllerProvider = YoYoControllerProvider(
      controller: widget.controller,
      child: const PlayerWithControls(),
    );

    return widget.controller.routePageBuilder!(
        context, animation, secondaryAnimation, controllerProvider);
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final TransitionRoute<void> route = PageRouteBuilder<void>(
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    onEnterFullScreen();

    if (widget.controller.allowedScreenSleep) {
      Wakelock.enable();
    }

    await Navigator.of(context, rootNavigator: true).push(route);
    _isFullScreen = false;
    widget.controller.exitFullScreen();

    Wakelock.disable();

    SystemChrome.setEnabledSystemUIOverlays(
        widget.controller.systemOverlaysAfterFullScreen!);
    SystemChrome.setPreferredOrientations(
        widget.controller.deviceOrientationsAfterFullScreen!);
  }

  void onEnterFullScreen() {
    final videoWidth = widget.controller.videoPlayerController.value.size.width;
    final videoHeight =
        widget.controller.videoPlayerController.value.size.height;

    if (widget.controller.systemOverlaysOnEnterFullScreen != null) {
      SystemChrome.setEnabledSystemUIOverlays(
          widget.controller.systemOverlaysOnEnterFullScreen!);
    } else {
      SystemChrome.setEnabledSystemUIOverlays([]);
    }

    if (widget.controller.deviceOrientationsOnEnterFullScreen != null) {
      SystemChrome.setPreferredOrientations(
          widget.controller.deviceOrientationsOnEnterFullScreen!);
    } else {
      final isLandscapeVideo = videoWidth > videoHeight;
      final isPortraitVideo = videoWidth < videoHeight;
      if (isLandscapeVideo) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else if (isPortraitVideo) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      }
    }
  }
}
