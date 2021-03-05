import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:yoyo_player/src/source/yoyo_progress_colors.dart';

class YoYoController extends ChangeNotifier {
  YoYoController({
    required this.videoPlayerController,
    this.aspectRatio,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.startAt,
    this.looping = false,
    this.fullScreenByDefault = false,
    this.cupertinoProgressColors,
    this.placeholder,
    this.overlay,
    this.showControlsOnInitialize = true,
    this.showControls = true,
    this.customControls,
    this.errorBuilder,
    this.allowedScreenSleep = true,
    this.isLive = false,
    this.allowFullScreen = true,
    this.allowMuting = true,
    this.allowPlaybackSpeedChanging = true,
    this.playbackSpeeds = const [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2],
    this.systemOverlaysOnEnterFullScreen,
    this.deviceOrientationsOnEnterFullScreen,
    this.systemOverlaysAfterFullScreen = SystemUiOverlay.values,
    this.deviceOrientationsAfterFullScreen = DeviceOrientation.values,
    this.routePageBuilder,
  })  : assert(videoPlayerController != null,
            'You must provide a controller to play a video'),
        assert(playbackSpeeds.every((speed) => speed > 0),
            'The playbackSpeeds values must all be greater than 0') {
    _initialize();
  }
  final VideoPlayerController videoPlayerController;
  final bool autoInitialize;
  final bool autoPlay;
  final Duration? startAt;
  final bool looping;
  final bool showControlsOnInitialize;
  final bool showControls;
  final Widget? customControls;
  final Widget Function(BuildContext context, String errorMessage)?
      errorBuilder;
  final double? aspectRatio;
  final YoYoProgressColors? cupertinoProgressColors;
  final Widget? placeholder;
  final Widget? overlay;
  final bool fullScreenByDefault;
  final bool allowedScreenSleep;
  final bool isLive;
  final bool allowFullScreen;
  final bool allowMuting;
  final bool allowPlaybackSpeedChanging;
  final List<double> playbackSpeeds;
  final List<SystemUiOverlay>? systemOverlaysOnEnterFullScreen;
  final List<DeviceOrientation>? deviceOrientationsOnEnterFullScreen;
  final List<SystemUiOverlay>? systemOverlaysAfterFullScreen;
  final List<DeviceOrientation>? deviceOrientationsAfterFullScreen;
  final YoYoRoutePageBuilder? routePageBuilder;

  static YoYoController of(BuildContext context) {
    final yoyoControllerProvider =
        context.dependOnInheritedWidgetOfExactType<YoYoControllerProvider>();

    return yoyoControllerProvider!.controller;
  }

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

  bool get isPlaying => videoPlayerController.value.isPlaying;

  Future _initialize() async {
    await videoPlayerController.setLooping(looping);

    if ((autoInitialize || autoPlay) &&
        !videoPlayerController.value.isInitialized) {
      await videoPlayerController.initialize();
    }

    if (autoPlay) {
      if (fullScreenByDefault) {
        enterFullScreen();
      }

      await videoPlayerController.play();
    }

    // await videoPlayerController.seekTo(startAt!);

    if (fullScreenByDefault) {
      videoPlayerController.addListener(_fullScreenListener);
    }
  }

  Future<void> _fullScreenListener() async {
    if (videoPlayerController.value.isPlaying && !_isFullScreen) {
      enterFullScreen();
      videoPlayerController.removeListener(_fullScreenListener);
    }
  }

  void enterFullScreen() {
    _isFullScreen = true;
    notifyListeners();
  }

  void exitFullScreen() {
    _isFullScreen = false;
    notifyListeners();
  }

  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  void togglePause() {
    isPlaying ? pause() : play();
  }

  Future<void> play() async {
    await videoPlayerController.play();
  }

  // ignore: avoid_positional_boolean_parameters
  Future<void> setLooping(bool looping) async {
    await videoPlayerController.setLooping(looping);
  }

  Future<void> pause() async {
    await videoPlayerController.pause();
  }

  Future<void> seekTo(Duration moment) async {
    await videoPlayerController.seekTo(moment);
  }

  Future<void> setVolume(double volume) async {
    await videoPlayerController.setVolume(volume);
  }
}

typedef YoYoRoutePageBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  YoYoControllerProvider controllerProvider,
);

class YoYoControllerProvider extends InheritedWidget {
  const YoYoControllerProvider({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  final YoYoController controller;

  @override
  bool updateShouldNotify(YoYoControllerProvider old) =>
      controller != old.controller;
}
