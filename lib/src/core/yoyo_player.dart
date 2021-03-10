// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// Package imports:
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wakelock/wakelock.dart';
import 'package:yoyo_player/src/configuration/yoyo_player_controller_event.dart';
import 'package:yoyo_player/src/core/yoyo_player_with_controls.dart';

import '../../yoyo_player.dart';
import 'yoyo_player_controller_provider.dart';
import 'yoyo_player_utils.dart';

///Widget which uses provided controller to render video player.
class YoYoPlayer extends StatefulWidget {
  const YoYoPlayer({Key? key, required this.controller}) : super(key: key);

  factory YoYoPlayer.network(
    String url, {
    YoYoPlayerConfiguration? yoyoPlayerConfiguration,
  }) =>
      YoYoPlayer(
        controller: YoYoPlayerController(
          yoyoPlayerConfiguration ?? const YoYoPlayerConfiguration(),
          yoyoPlayerDataSource:
              YoYoPlayerDataSource(YoYoPlayerDataSourceType.network, url),
        ),
      );

  factory YoYoPlayer.file(
    String url, {
    YoYoPlayerConfiguration? yoyoPlayerConfiguration,
  }) =>
      YoYoPlayer(
        controller: YoYoPlayerController(
          yoyoPlayerConfiguration ?? const YoYoPlayerConfiguration(),
          yoyoPlayerDataSource:
              YoYoPlayerDataSource(YoYoPlayerDataSourceType.file, url),
        ),
      );

  final YoYoPlayerController controller;

  @override
  _YoYoPlayerState createState() {
    return _YoYoPlayerState();
  }
}

class _YoYoPlayerState extends State<YoYoPlayer> with WidgetsBindingObserver {
  YoYoPlayerConfiguration get _yoyoPlayerConfiguration =>
      widget.controller.yoyoPlayerConfiguration;

  bool _isFullScreen = false;

  ///State of navigator on widget created
  late NavigatorState _navigatorState;

  ///Flag which determines if widget has initialized
  bool _initialized = false;

  ///Subscription for controller events
  StreamSubscription? _controllerEventSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    if (!_initialized) {
      final navigator = Navigator.of(context);
      setState(() {
        _navigatorState = navigator;
      });
      _setup();
      _initialized = true;
    }
    super.didChangeDependencies();
  }

  Future<void> _setup() async {
    _controllerEventSubscription =
        widget.controller.controllerEventStream.listen(onControllerEvent);

    //Default locale
    var locale = const Locale("en", "US");
    try {
      if (mounted) {
        final contextLocale = Localizations.localeOf(context);
        locale = contextLocale;
      }
    } catch (exception) {
      YoYoPlayerUtils.log(exception.toString());
    }
    widget.controller.setupTranslations(locale);
  }

  @override
  void dispose() {
    ///If somehow BetterPlayer widget has been disposed from widget tree and
    ///full screen is on, then full screen route must be pop and return to normal
    ///state.
    if (_isFullScreen) {
      Wakelock.disable();
      _navigatorState.maybePop();
      SystemChrome.setEnabledSystemUIOverlays(
          _yoyoPlayerConfiguration.systemOverlaysAfterFullScreen);
      SystemChrome.setPreferredOrientations(
          _yoyoPlayerConfiguration.deviceOrientationsAfterFullScreen);
    }

    WidgetsBinding.instance!.removeObserver(this);
    _controllerEventSubscription?.cancel();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(YoYoPlayer oldWidget) {
    if (oldWidget.controller != widget.controller) {
      _controllerEventSubscription?.cancel();
      _controllerEventSubscription =
          widget.controller.controllerEventStream.listen(onControllerEvent);
    }
    super.didUpdateWidget(oldWidget);
  }

  void onControllerEvent(YoYoPlayerControllerEvent event) {
    switch (event) {
      case YoYoPlayerControllerEvent.openFullscreen:
        onFullScreenChanged();
        break;
      case YoYoPlayerControllerEvent.hideFullscreen:
        onFullScreenChanged();
        break;
      default:
        setState(() {});
        break;
    }
  }

  // ignore: avoid_void_async
  Future<void> onFullScreenChanged() async {
    final controller = widget.controller;
    if (controller.isFullScreen && !_isFullScreen) {
      _isFullScreen = true;
      controller.postEvent(YoYoPlayerEvent(YoYoPlayerEventType.openFullscreen));
      await _pushFullScreenWidget(context);
    } else if (_isFullScreen) {
      Navigator.of(context, rootNavigator: true).pop();
      _isFullScreen = false;
      controller.postEvent(YoYoPlayerEvent(YoYoPlayerEventType.hideFullscreen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoYoPlayerControllerProvider(
      controller: widget.controller,
      child: _buildPlayer(),
    );
  }

  Widget _buildFullScreenVideo(
      BuildContext context,
      Animation<double> animation,
      YoYoPlayerControllerProvider controllerProvider) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: controllerProvider,
      ),
    );
  }

  AnimatedWidget _defaultRoutePageBuilder(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      YoYoPlayerControllerProvider controllerProvider) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return _buildFullScreenVideo(context, animation, controllerProvider);
      },
    );
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final controllerProvider = YoYoPlayerControllerProvider(
        controller: widget.controller, child: _buildPlayer());

    final routePageBuilder = _yoyoPlayerConfiguration.routePageBuilder;
    if (routePageBuilder == null) {
      return _defaultRoutePageBuilder(
          context, animation, secondaryAnimation, controllerProvider);
    }

    return routePageBuilder(
        context, animation, secondaryAnimation, controllerProvider);
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final TransitionRoute<void> route = PageRouteBuilder<void>(
      settings: const RouteSettings(),
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    await SystemChrome.setEnabledSystemUIOverlays([]);

    if (isAndroid) {
      if (_yoyoPlayerConfiguration.autoDetectFullscreenDeviceOrientation ==
          true) {
        final aspectRatio =
            widget.controller.videoPlayerController?.value.aspectRatio ?? 1.0;
        List<DeviceOrientation> deviceOrientations;
        if (aspectRatio < 1.0) {
          deviceOrientations = [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown
          ];
        } else {
          deviceOrientations = [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight
          ];
        }
        await SystemChrome.setPreferredOrientations(deviceOrientations);
      } else {
        await SystemChrome.setPreferredOrientations(
          widget.controller.yoyoPlayerConfiguration
              .deviceOrientationsOnFullScreen,
        );
      }
    } else {
      await SystemChrome.setPreferredOrientations(
        widget
            .controller.yoyoPlayerConfiguration.deviceOrientationsOnFullScreen,
      );
    }

    if (!_yoyoPlayerConfiguration.allowedScreenSleep) {
      Wakelock.enable();
    }

    await Navigator.of(context, rootNavigator: true).push(route);
    _isFullScreen = false;
    widget.controller.exitFullScreen();

    // The wakelock plugins checks whether it needs to perform an action internally,
    // so we do not need to check Wakelock.isEnabled.
    Wakelock.disable();

    await SystemChrome.setEnabledSystemUIOverlays(
        _yoyoPlayerConfiguration.systemOverlaysAfterFullScreen);
    await SystemChrome.setPreferredOrientations(
        _yoyoPlayerConfiguration.deviceOrientationsAfterFullScreen);
  }

  Widget _buildPlayer() {
    return VisibilityDetector(
      key: Key("${widget.controller.hashCode}_key"),
      onVisibilityChanged: (VisibilityInfo info) =>
          widget.controller.onPlayerVisibilityChanged(info.visibleFraction),
      child: YoYoPlayerWithControls(
        controller: widget.controller,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    widget.controller.setAppLifecycleState(state);
  }
}

///Page route builder used in fullscreen mode.
typedef YoYoPlayerRoutePageBuilder = Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    YoYoPlayerControllerProvider controllerProvider);
