// Dart imports:
import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';

// Package imports:
import 'package:path_provider/path_provider.dart';
import 'package:yoyo_player/src/configuration/yoyo_player_controller_event.dart';
import 'package:yoyo_player/src/hls/yoyo_player_hls_audio_track.dart';
import 'package:yoyo_player/src/hls/yoyo_player_hls_track.dart';
import 'package:yoyo_player/src/hls/yoyo_player_hls_utils.dart';
import 'package:yoyo_player/src/subtitles/yoyo_player_subtitle.dart';
import 'package:yoyo_player/src/subtitles/yoyo_player_subtitles_factory.dart';
import 'package:yoyo_player/src/video_player/video_player.dart';
import 'package:yoyo_player/src/video_player/video_player_platform_interface.dart';

import '../../yoyo_player.dart';
import 'yoyo_player_utils.dart';

///Class used to control overall Better Player behavior. Main class to change
///state of Better Player.
class YoYoPlayerController {
  static const String _durationParameter = "duration";
  static const String _progressParameter = "progress";
  static const String _volumeParameter = "volume";
  static const String _speedParameter = "speed";
  static const String _dataSourceParameter = "dataSource";
  static const String _hlsExtension = "m3u8";
  static const String _authorizationHeader = "Authorization";

  ///General configuration used in controller instance.
  final YoYoPlayerConfiguration yoyoPlayerConfiguration;

  ///Playlist configuration used in controller instance.
  final YoYoPlayerPlaylistConfiguration? yoyoPlayerPlaylistConfiguration;

  ///List of event listeners, which listen to events.
  final List<Function(YoYoPlayerEvent)?> _eventListeners = [];

  ///List of files to delete once player disposes.
  final List<File> _tempFiles = [];

  ///Stream controller which emits stream when control visibility changes.
  final StreamController<bool> _controlsVisibilityStreamController =
      StreamController.broadcast();

  ///Instance of video player controller which is adapter used to communicate
  ///between flutter high level code and lower level native code.
  VideoPlayerController? videoPlayerController;

  /// Defines a event listener where video player events will be send.
  Function(YoYoPlayerEvent)? get eventListener =>
      yoyoPlayerConfiguration.eventListener;

  ///Flag used to store full screen mode state.
  bool _isFullScreen = false;

  ///Flag used to store full screen mode state.
  bool get isFullScreen => _isFullScreen;

  ///Time when last progress event was sent
  int _lastPositionSelection = 0;

  ///Currently used data source in player.
  YoYoPlayerDataSource? _yoyoPlayerDataSource;

  ///Currently used data source in player.
  YoYoPlayerDataSource? get yoyoPlayerDataSource => _yoyoPlayerDataSource;

  ///List of BetterPlayerSubtitlesSources.
  final List<YoYoPlayerSubtitlesSource> _yoyoPlayerSubtitlesSourceList = [];

  ///List of BetterPlayerSubtitlesSources.
  List<YoYoPlayerSubtitlesSource> get yoyoPlayerSubtitlesSourceList =>
      _yoyoPlayerSubtitlesSourceList;
  YoYoPlayerSubtitlesSource? _yoyoPlayerSubtitlesSource;

  ///Currently used subtitles source.
  YoYoPlayerSubtitlesSource? get yoyoPlayerSubtitlesSource =>
      _yoyoPlayerSubtitlesSource;

  ///Subtitles lines for current data source.
  List<YoYoPlayerSubtitle> subtitlesLines = [];

  ///List of tracks available for current data source. Used only for HLS.
  List<YoYoPlayerHlsTrack> _yoyoPlayerTracks = [];

  ///List of tracks available for current data source. Used only for HLS.
  List<YoYoPlayerHlsTrack> get yoyoPlayerTracks => _yoyoPlayerTracks;

  ///Currently selected player track. Used only for HLS.
  YoYoPlayerHlsTrack? _yoyoPlayerTrack;

  ///Currently selected player track. Used only for HLS.
  YoYoPlayerHlsTrack? get yoyoPlayerTrack => _yoyoPlayerTrack;

  ///Timer for next video. Used in playlist.
  Timer? _nextVideoTimer;

  ///Time for next video.
  int? _nextVideoTime;

  ///Stream controller which emits next video time.
  StreamController<int?> nextVideoTimeStreamController =
      StreamController.broadcast();

  ///Has player been disposed.
  bool _disposed = false;

  ///Was player playing before automatic pause.
  bool? _wasPlayingBeforePause;

  ///Currently used translations
  YoYoPlayerTranslations translations = YoYoPlayerTranslations();

  ///Has current data source started
  bool _hasCurrentDataSourceStarted = false;

  ///Has current data source initialized
  bool _hasCurrentDataSourceInitialized = false;

  ///Stream which sends flag whenever visibility of controls changes
  Stream<bool> get controlsVisibilityStream =>
      _controlsVisibilityStreamController.stream;

  ///Current app lifecycle state.
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  ///Flag which determines if controls (UI interface) is shown. When false,
  ///UI won't be shown (show only player surface).
  bool _controlsEnabled = true;

  ///Flag which determines if controls (UI interface) is shown. When false,
  ///UI won't be shown (show only player surface).
  bool get controlsEnabled => _controlsEnabled;

  ///Overridden aspect ratio which will be used instead of aspect ratio passed
  ///in configuration.
  double? _overriddenAspectRatio;

  ///Was Picture in Picture opened.
  bool _wasInPipMode = false;

  ///Was player in fullscreen before Picture in Picture opened.
  bool _wasInFullScreenBeforePiP = false;

  ///Was controls enabled before Picture in Picture opened.
  bool _wasControlsEnabledBeforePiP = false;

  ///GlobalKey of the BetterPlayer widget
  GlobalKey? _yoyoPlayerGlobalKey;

  ///Getter of the GlobalKey
  GlobalKey? get yoyoPlayerGlobalKey => _yoyoPlayerGlobalKey;

  ///StreamSubscription for VideoEvent listener
  StreamSubscription<VideoEvent>? _videoEventStreamSubscription;

  ///Are controls always visible
  bool _controlsAlwaysVisible = false;

  ///Are controls always visible
  bool get controlsAlwaysVisible => _controlsAlwaysVisible;

  ///List of all possible audio tracks returned from HLS stream
  List<YoYoPlayerHlsAudioTrack>? _yoyoPlayerAudioTracks;

  ///List of all possible audio tracks returned from HLS stream
  List<YoYoPlayerHlsAudioTrack>? get betterPlayerAudioTracks =>
      _yoyoPlayerAudioTracks;

  ///Selected HLS audio track
  YoYoPlayerHlsAudioTrack? _yoyoPlayerHlsAudioTrack;

  ///Selected HLS audio track
  YoYoPlayerHlsAudioTrack? get yoyoPlayerAudioTrack => _yoyoPlayerHlsAudioTrack;

  ///Selected videoPlayerValue when error occurred.
  VideoPlayerValue? _videoPlayerValueOnError;

  ///Flag which holds information about player visibility
  bool _isPlayerVisible = true;

  final StreamController<YoYoPlayerControllerEvent>
      _controllerEventStreamController = StreamController.broadcast();

  ///Stream of internal controller events. Shouldn't be used inside app. For
  ///normal events, use eventListener.
  Stream<YoYoPlayerControllerEvent> get controllerEventStream =>
      _controllerEventStreamController.stream;

  YoYoPlayerController(
    this.yoyoPlayerConfiguration, {
    this.yoyoPlayerPlaylistConfiguration,
    YoYoPlayerDataSource? yoyoPlayerDataSource,
  }) {
    _eventListeners.add(eventListener);
    if (yoyoPlayerDataSource != null) {
      setupDataSource(yoyoPlayerDataSource);
    }
  }

  ///Get BetterPlayerController from context. Used in InheritedWidget.
  static YoYoPlayerController of(BuildContext context) {
    final yoyoPLayerControllerProvider = context
        .dependOnInheritedWidgetOfExactType<YoYoPlayerControllerProvider>()!;

    return yoyoPLayerControllerProvider.controller;
  }

  ///Setup new data source in Better Player.
  Future setupDataSource(YoYoPlayerDataSource yoyoPlayerDataSource) async {
    postEvent(YoYoPlayerEvent(YoYoPlayerEventType.setupDataSource,
        parameters: <String, dynamic>{
          _dataSourceParameter: yoyoPlayerDataSource,
        }));
    _postControllerEvent(YoYoPlayerControllerEvent.setupDataSource);
    _hasCurrentDataSourceStarted = false;
    _hasCurrentDataSourceInitialized = false;
    _yoyoPlayerDataSource = yoyoPlayerDataSource;

    ///Build videoPlayerController if null
    if (videoPlayerController == null) {
      videoPlayerController = VideoPlayerController();
      videoPlayerController?.addListener(_onVideoPlayerChanged);
    }

    ///Clear hls tracks
    yoyoPlayerTracks.clear();

    ///Setup subtitles
    final List<YoYoPlayerSubtitlesSource>? yoyoPlayerSubtitlesSourceList =
        yoyoPlayerDataSource.subtitles;
    if (yoyoPlayerSubtitlesSourceList != null) {
      _yoyoPlayerSubtitlesSourceList.addAll(yoyoPlayerDataSource.subtitles!);
    }

    if (_isDataSourceHls(yoyoPlayerDataSource)) {
      _setupHlsDataSource().then((dynamic value) {
        _setupSubtitles();
      });
    } else {
      _setupSubtitles();
    }

    ///Process data source
    await _setupDataSource(yoyoPlayerDataSource);
    setTrack(YoYoPlayerHlsTrack.defaultTrack());
  }

  ///Configure subtitles based on subtitles source.
  void _setupSubtitles() {
    _yoyoPlayerSubtitlesSourceList.add(
      YoYoPlayerSubtitlesSource(type: YoYoPlayerSubtitlesSourceType.none),
    );
    final defaultSubtitle = _yoyoPlayerSubtitlesSourceList
        .firstWhereOrNull((element) => element.selectedByDefault == true);

    ///Setup subtitles (none is default)
    setupSubtitleSource(defaultSubtitle ?? _yoyoPlayerSubtitlesSourceList.last,
        sourceInitialize: true);
  }

  ///Check if given [yoyoPlayerDataSource] is HLS-type data source.
  bool _isDataSourceHls(YoYoPlayerDataSource yoyoPlayerDataSource) =>
      yoyoPlayerDataSource.url.contains(_hlsExtension) ||
      yoyoPlayerDataSource.videoFormat == YoYoPlayerVideoFormat.hls;

  ///Configure HLS data source based on provided data source and configuration.
  ///This method configures tracks, subtitles and audio tracks from given
  ///master playlist.
  Future _setupHlsDataSource() async {
    final String? hlsData = await YoYoPlayerHlsUtils.getDataFromUrl(
      yoyoPlayerDataSource!.url,
      _getHeaders(),
    );
    if (hlsData != null) {
      /// Load hls tracks
      if (_yoyoPlayerDataSource?.useHlsTracks == true) {
        _yoyoPlayerTracks = await YoYoPlayerHlsUtils.parseTracks(
            hlsData, yoyoPlayerDataSource!.url);
      }

      /// Load hls subtitles
      if (yoyoPlayerDataSource?.useHlsSubtitles == true) {
        final hlsSubtitles = await YoYoPlayerHlsUtils.parseSubtitles(
            hlsData, yoyoPlayerDataSource!.url);
        hlsSubtitles.forEach((hlsSubtitle) {
          _yoyoPlayerSubtitlesSourceList.add(
            YoYoPlayerSubtitlesSource(
                type: YoYoPlayerSubtitlesSourceType.network,
                name: hlsSubtitle.name,
                urls: hlsSubtitle.realUrls),
          );
        });
      }

      ///Load audio tracks
      if (yoyoPlayerDataSource?.useHlsAudioTracks == true &&
          _isDataSourceHls(yoyoPlayerDataSource!)) {
        _yoyoPlayerAudioTracks = await YoYoPlayerHlsUtils.parseLanguages(
            hlsData, yoyoPlayerDataSource!.url);
        if (_yoyoPlayerAudioTracks?.isNotEmpty == true) {
          setAudioTrack(_yoyoPlayerAudioTracks!.first);
        }
      }
    }
  }

  ///Setup subtitles to be displayed from given subtitle source
  Future<void> setupSubtitleSource(YoYoPlayerSubtitlesSource subtitlesSource,
      {bool sourceInitialize = false}) async {
    _yoyoPlayerSubtitlesSource = subtitlesSource;
    subtitlesLines.clear();
    if (subtitlesSource.type != YoYoPlayerSubtitlesSourceType.none) {
      final subtitlesParsed =
          await YoYoPlayerSubtitlesFactory.parseSubtitles(subtitlesSource);
      subtitlesLines.addAll(subtitlesParsed);
    }

    _postEvent(YoYoPlayerEvent(YoYoPlayerEventType.changedSubtitles));
    if (!_disposed && !sourceInitialize) {
      _postControllerEvent(YoYoPlayerControllerEvent.changeSubtitles);
    }
  }

  ///Get VideoFormat from YoYoPlayerVideoFormat (adapter method which translates
  ///to video_player supported format).
  VideoFormat? _getVideoFormat(YoYoPlayerVideoFormat? yoyoPlayerVideoFormat) {
    if (yoyoPlayerVideoFormat == null) {
      return null;
    }
    switch (yoyoPlayerVideoFormat) {
      case YoYoPlayerVideoFormat.dash:
        return VideoFormat.dash;
      case YoYoPlayerVideoFormat.hls:
        return VideoFormat.hls;
      case YoYoPlayerVideoFormat.ss:
        return VideoFormat.ss;
      case YoYoPlayerVideoFormat.other:
        return VideoFormat.other;
    }
  }

  ///Internal method which invokes videoPlayerController source setup.
  Future _setupDataSource(YoYoPlayerDataSource yoyoPlayerDataSource) async {
    switch (yoyoPlayerDataSource.type) {
      case YoYoPlayerDataSourceType.network:
        await videoPlayerController?.setNetworkDataSource(
          yoyoPlayerDataSource.url,
          headers: _getHeaders(),
          useCache:
              _yoyoPlayerDataSource!.cacheConfiguration?.useCache ?? false,
          maxCacheSize:
              _yoyoPlayerDataSource!.cacheConfiguration?.maxCacheSize ?? 0,
          maxCacheFileSize:
              _yoyoPlayerDataSource!.cacheConfiguration?.maxCacheFileSize ?? 0,
          showNotification: _yoyoPlayerDataSource
              ?.notificationConfiguration?.showNotification,
          title: _yoyoPlayerDataSource?.notificationConfiguration?.title,
          author: _yoyoPlayerDataSource?.notificationConfiguration?.author,
          imageUrl: _yoyoPlayerDataSource?.notificationConfiguration?.imageUrl,
          notificationChannelName: _yoyoPlayerDataSource
              ?.notificationConfiguration?.notificationChannelName,
          overriddenDuration: _yoyoPlayerDataSource!.overriddenDuration,
          formatHint: _getVideoFormat(_yoyoPlayerDataSource!.videoFormat),
          licenseUrl: _yoyoPlayerDataSource?.drmConfiguration?.licenseUrl,
          drmHeaders: _yoyoPlayerDataSource?.drmConfiguration?.headers,
        );

        break;
      case YoYoPlayerDataSourceType.file:
        await videoPlayerController?.setFileDataSource(
          File(yoyoPlayerDataSource.url),
          showNotification: _yoyoPlayerDataSource
              ?.notificationConfiguration?.showNotification,
          title: _yoyoPlayerDataSource?.notificationConfiguration?.title,
          author: _yoyoPlayerDataSource?.notificationConfiguration?.author,
          imageUrl: _yoyoPlayerDataSource?.notificationConfiguration?.imageUrl,
          notificationChannelName: _yoyoPlayerDataSource
              ?.notificationConfiguration?.notificationChannelName,
          overriddenDuration: _yoyoPlayerDataSource!.overriddenDuration,
        );
        break;
      case YoYoPlayerDataSourceType.memory:
        final file = await _createFile(_yoyoPlayerDataSource!.bytes!,
            extension: _yoyoPlayerDataSource!.videoExtension);

        if (file.existsSync()) {
          await videoPlayerController?.setFileDataSource(
            file,
            showNotification: _yoyoPlayerDataSource
                ?.notificationConfiguration?.showNotification,
            title: _yoyoPlayerDataSource?.notificationConfiguration?.title,
            author: _yoyoPlayerDataSource?.notificationConfiguration?.author,
            imageUrl:
                _yoyoPlayerDataSource?.notificationConfiguration?.imageUrl,
            notificationChannelName: _yoyoPlayerDataSource
                ?.notificationConfiguration?.notificationChannelName,
            overriddenDuration: _yoyoPlayerDataSource!.overriddenDuration,
          );
          _tempFiles.add(file);
        } else {
          throw ArgumentError("Couldn't create file from memory.");
        }
        break;

      default:
        throw UnimplementedError(
            "${yoyoPlayerDataSource.type} is not implemented");
    }
    await _initializeVideo();
  }

  ///Create file from provided list of bytes. File will be created in temporary
  ///directory.
  Future<File> _createFile(List<int> bytes,
      {String? extension = "temp"}) async {
    final String dir = (await getTemporaryDirectory()).path;
    final File temp = File(
        '$dir/better_player_${DateTime.now().millisecondsSinceEpoch}.$extension');
    await temp.writeAsBytes(bytes);
    return temp;
  }

  ///Initializes video based on configuration. Invoke actions which need to be
  ///run on player start.
  Future _initializeVideo() async {
    setLooping(yoyoPlayerConfiguration.looping);
    _videoEventStreamSubscription = videoPlayerController
        ?.videoEventStreamController.stream
        .listen(_handleVideoEvent);

    final fullScreenByDefault = yoyoPlayerConfiguration.fullScreenByDefault;
    if (yoyoPlayerConfiguration.autoPlay) {
      if (fullScreenByDefault) {
        enterFullScreen();
      }
      if (_isAutomaticPlayPauseHandled()) {
        if (_appLifecycleState == AppLifecycleState.resumed &&
            _isPlayerVisible) {
          await play();
        } else {
          _wasPlayingBeforePause = true;
        }
      } else {
        await play();
      }
    } else {
      if (fullScreenByDefault) {
        enterFullScreen();
      }
    }

    final startAt = yoyoPlayerConfiguration.startAt;
    if (startAt != null) {
      seekTo(startAt);
    }
  }

  ///Method which is invoked when full screen changes.
  Future<void> _onFullScreenStateChanged() async {
    if (videoPlayerController?.value.isPlaying == true && !_isFullScreen) {
      enterFullScreen();
      videoPlayerController?.removeListener(_onFullScreenStateChanged);
    }
  }

  ///Enables full screen mode in player. This will trigger route change.
  void enterFullScreen() {
    _isFullScreen = true;
    _postControllerEvent(YoYoPlayerControllerEvent.openFullscreen);
  }

  ///Disables full screen mode in player. This will trigger route change.
  void exitFullScreen() {
    _isFullScreen = false;
    _postControllerEvent(YoYoPlayerControllerEvent.hideFullscreen);
  }

  ///Enables/disables full screen mode based on current fullscreen state.
  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    if (_isFullScreen) {
      _postControllerEvent(YoYoPlayerControllerEvent.openFullscreen);
    } else {
      _postControllerEvent(YoYoPlayerControllerEvent.hideFullscreen);
    }
  }

  ///Start video playback. Play will be triggered only if current lifecycle state
  ///is resumed.
  Future<void> play() async {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }

    if (_appLifecycleState == AppLifecycleState.resumed) {
      await videoPlayerController!.play();
      _hasCurrentDataSourceStarted = true;
      _wasPlayingBeforePause = null;
      _postEvent(YoYoPlayerEvent(YoYoPlayerEventType.play));
      _postControllerEvent(YoYoPlayerControllerEvent.play);
    }
  }

  ///Enables/disables looping (infinity playback) mode.
  Future<void> setLooping(bool looping) async {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }

    await videoPlayerController!.setLooping(looping);
  }

  ///Stop video playback.
  Future<void> pause() async {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }

    await videoPlayerController!.pause();
    _postEvent(YoYoPlayerEvent(YoYoPlayerEventType.pause));
  }

  ///Move player to specific position/moment of the video.
  Future<void> seekTo(Duration moment) async {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }
    await videoPlayerController!.seekTo(moment);

    _postEvent(YoYoPlayerEvent(YoYoPlayerEventType.seekTo,
        parameters: <String, dynamic>{_durationParameter: moment}));

    final Duration? currentDuration = videoPlayerController!.value.duration;
    if (currentDuration == null) {
      return;
    }
    if (moment > currentDuration) {
      _postEvent(YoYoPlayerEvent(YoYoPlayerEventType.finished));
    } else {
      cancelNextVideoTimer();
    }
  }

  ///Set volume of player. Allows values from 0.0 to 1.0.
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) {
      throw ArgumentError("Volume must be between 0.0 and 1.0");
    }
    if (videoPlayerController == null) {
      YoYoPlayerUtils.log("The data source has not been initialized");
      return;
    }
    await videoPlayerController!.setVolume(volume);
    _postEvent(YoYoPlayerEvent(YoYoPlayerEventType.setVolume,
        parameters: <String, dynamic>{_volumeParameter: volume}));
  }

  ///Set playback speed of video. Allows to set speed value between 0 and 2.
  Future<void> setSpeed(double speed) async {
    if (speed < 0 || speed > 2) {
      throw ArgumentError("Speed must be between 0 and 2");
    }
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }
    await videoPlayerController?.setSpeed(speed);
    _postEvent(
      YoYoPlayerEvent(
        YoYoPlayerEventType.setSpeed,
        parameters: <String, dynamic>{
          _speedParameter: speed,
        },
      ),
    );
  }

  ///Flag which determines whenever player is playing or not.
  bool? isPlaying() {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }
    return videoPlayerController!.value.isPlaying;
  }

  ///Flag which determines whenever player is loading video data or not.
  bool? isBuffering() {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }
    return videoPlayerController!.value.isBuffering;
  }

  ///Show or hide controls manually
  void setControlsVisibility(bool isVisible) {
    _controlsVisibilityStreamController.add(isVisible);
  }

  ///Enable/disable controls (when enabled = false, controls will be always hidden)
  void setControlsEnabled(bool enabled) {
    if (!enabled) {
      _controlsVisibilityStreamController.add(false);
    }
    _controlsEnabled = enabled;
  }

  ///Internal method, used to trigger CONTROLS_VISIBLE or CONTROLS_HIDDEN event
  ///once controls state changed.
  void toggleControlsVisibility(bool isVisible) {
    _postEvent(isVisible
        ? YoYoPlayerEvent(YoYoPlayerEventType.controlsVisible)
        : YoYoPlayerEvent(YoYoPlayerEventType.controlsHidden));
  }

  ///Send player event. Shouldn't be used manually.
  void postEvent(YoYoPlayerEvent betterPlayerEvent) {
    _postEvent(betterPlayerEvent);
  }

  ///Send player event to all listeners.
  void _postEvent(YoYoPlayerEvent betterPlayerEvent) {
    for (final Function(YoYoPlayerEvent)? eventListener in _eventListeners) {
      if (eventListener != null) {
        eventListener(betterPlayerEvent);
      }
    }
  }

  ///Listener used to handle video player changes.
  void _onVideoPlayerChanged() async {
    final VideoPlayerValue currentVideoPlayerValue =
        videoPlayerController?.value ??
            VideoPlayerValue(duration: const Duration());

    if (currentVideoPlayerValue.hasError) {
      _videoPlayerValueOnError ??= currentVideoPlayerValue;
      _postEvent(
        YoYoPlayerEvent(
          YoYoPlayerEventType.exception,
          parameters: <String, dynamic>{
            "exception": currentVideoPlayerValue.errorDescription
          },
        ),
      );
    }
    if (currentVideoPlayerValue.initialized &&
        !_hasCurrentDataSourceInitialized) {
      _hasCurrentDataSourceInitialized = true;
      _postEvent(YoYoPlayerEvent(YoYoPlayerEventType.initialized));
    }
    if (currentVideoPlayerValue.isPip) {
      _wasInPipMode = true;
    } else if (_wasInPipMode) {
      _postEvent(YoYoPlayerEvent(YoYoPlayerEventType.pipStop));
      _wasInPipMode = false;
      if (!_wasInFullScreenBeforePiP) {
        exitFullScreen();
      }
      if (_wasControlsEnabledBeforePiP) {
        setControlsEnabled(true);
      }
      videoPlayerController?.refresh();
    }

    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPositionSelection > 500) {
      _lastPositionSelection = now;
      _postEvent(
        YoYoPlayerEvent(
          YoYoPlayerEventType.progress,
          parameters: <String, dynamic>{
            _progressParameter: currentVideoPlayerValue.position,
            _durationParameter: currentVideoPlayerValue.duration
          },
        ),
      );
    }
  }

  ///Add event listener which listens to player events.
  void addEventsListener(Function(YoYoPlayerEvent) eventListener) {
    _eventListeners.add(eventListener);
  }

  ///Remove event listener. This method should be called once you're disposing
  ///Better Player.
  void removeEventsListener(Function(YoYoPlayerEvent) eventListener) {
    _eventListeners.remove(eventListener);
  }

  ///Flag which determines whenever player is playing live data source.
  bool isLiveStream() {
    if (_yoyoPlayerDataSource == null) {
      throw StateError("The data source has not been initialized");
    }
    return _yoyoPlayerDataSource!.liveStream == true;
  }

  ///Flag which determines whenever player data source has been initialized.
  bool? isVideoInitialized() {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }
    return videoPlayerController?.value.initialized;
  }

  ///Start timer which will trigger next video. Used in playlist. Do not use
  ///manually.
  void startNextVideoTimer() {
    if (_nextVideoTimer == null) {
      _nextVideoTime =
          yoyoPlayerPlaylistConfiguration!.nextVideoDelay.inSeconds;
      nextVideoTimeStreamController.add(_nextVideoTime);
      _nextVideoTimer =
          Timer.periodic(const Duration(milliseconds: 1000), (_timer) async {
        if (_nextVideoTime == 1) {
          _timer.cancel();
          _nextVideoTimer = null;
        }
        if (_nextVideoTime != null) {
          _nextVideoTime = _nextVideoTime! - 1;
        }
        nextVideoTimeStreamController.add(_nextVideoTime);
      });
    }
  }

  ///Cancel next video timer. Used in playlist. Do not use manually.
  void cancelNextVideoTimer() {
    _nextVideoTime = null;
    nextVideoTimeStreamController.add(_nextVideoTime);
    _nextVideoTimer?.cancel();
    _nextVideoTimer = null;
  }

  ///Play next video form playlist. Do not use manually.
  void playNextVideo() {
    _nextVideoTime = 0;
    nextVideoTimeStreamController.add(_nextVideoTime);
    cancelNextVideoTimer();
  }

  ///Setup track parameters for currently played video. Can be used only for HLS
  ///data source.
  void setTrack(YoYoPlayerHlsTrack track) {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }
    _postEvent(YoYoPlayerEvent(YoYoPlayerEventType.changedTrack));

    videoPlayerController!
        .setTrackParameters(track.width, track.height, track.bitrate);
    _yoyoPlayerTrack = track;
  }

  ///Check if player can be played/paused automatically
  bool _isAutomaticPlayPauseHandled() {
    return !(_yoyoPlayerDataSource
                ?.notificationConfiguration?.showNotification ==
            true) &&
        yoyoPlayerConfiguration.handleLifecycle;
  }

  ///Listener which handles state of player visibility. If player visibility is
  ///below 0.0 then video will be paused. When value is greater than 0, video
  ///will play again. If there's different handler of visibility then it will be
  ///used. If showNotification is set in data source or handleLifecycle is false
  /// then this logic will be ignored.
  void onPlayerVisibilityChanged(double visibilityFraction) async {
    _isPlayerVisible = visibilityFraction > 0;
    if (_disposed) {
      return;
    }
    _postEvent(YoYoPlayerEvent(YoYoPlayerEventType.changedPlayerVisibility));

    if (_isAutomaticPlayPauseHandled()) {
      if (yoyoPlayerConfiguration.playerVisibilityChangedBehavior != null) {
        yoyoPlayerConfiguration
            .playerVisibilityChangedBehavior!(visibilityFraction);
      } else {
        if (visibilityFraction == 0) {
          _wasPlayingBeforePause ??= isPlaying();
          pause();
        } else {
          if (_wasPlayingBeforePause == true && !isPlaying()!) {
            play();
          }
        }
      }
    }
  }

  ///Set different resolution (quality) for video
  void setResolution(String url) async {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }
    final position = await videoPlayerController!.position;
    final wasPlayingBeforeChange = isPlaying()!;
    pause();
    await setupDataSource(yoyoPlayerDataSource!.copyWith(url: url));
    seekTo(position!);
    if (wasPlayingBeforeChange) {
      play();
    }
    _postEvent(YoYoPlayerEvent(YoYoPlayerEventType.changedResolution));
  }

  ///Setup translations for given locale. In normal use cases it shouldn't be
  ///called manually.
  void setupTranslations(Locale locale) {
    // ignore: unnecessary_null_comparison
    if (locale != null) {
      final String languageCode = locale.languageCode;
      translations = yoyoPlayerConfiguration.translations?.firstWhereOrNull(
              (translations) => translations.languageCode == languageCode) ??
          _getDefaultTranslations(locale);
    } else {
      YoYoPlayerUtils.log("Locale is null. Couldn't setup translations.");
    }
  }

  ///Setup default translations for selected user locale. These translations
  ///are pre-build in.
  YoYoPlayerTranslations _getDefaultTranslations(Locale locale) {
    final String languageCode = locale.languageCode;
    switch (languageCode) {
      case "pl":
        return YoYoPlayerTranslations.polish();
      case "zh":
        return YoYoPlayerTranslations.chinese();
      case "hi":
        return YoYoPlayerTranslations.hindi();
      default:
        return YoYoPlayerTranslations();
    }
  }

  ///Flag which determines whenever current data source has started.
  bool get hasCurrentDataSourceStarted => _hasCurrentDataSourceStarted;

  ///Set current lifecycle state. If state is [AppLifecycleState.resumed] then
  ///player starts playing again. if lifecycle is in [AppLifecycleState.paused]
  ///state, then video playback will stop. If showNotification is set in data
  ///source or handleLifecycle is false then this logic will be ignored.
  void setAppLifecycleState(AppLifecycleState appLifecycleState) {
    if (_isAutomaticPlayPauseHandled()) {
      _appLifecycleState = appLifecycleState;
      if (appLifecycleState == AppLifecycleState.resumed) {
        if (_wasPlayingBeforePause == true && _isPlayerVisible) {
          play();
        }
      }
      if (appLifecycleState == AppLifecycleState.paused) {
        _wasPlayingBeforePause ??= isPlaying();
        pause();
      }
    }
  }

  // ignore: use_setters_to_change_properties
  ///Setup overridden aspect ratio.
  void setOverriddenAspectRatio(double aspectRatio) {
    _overriddenAspectRatio = aspectRatio;
  }

  ///Get aspect ratio used in current video. If aspect ratio is null, then
  ///aspect ratio from BetterPlayerConfiguration will be used. Otherwise
  ///[_overriddenAspectRatio] will be used.
  double? getAspectRatio() {
    return _overriddenAspectRatio ?? yoyoPlayerConfiguration.aspectRatio;
  }

  ///Enable Picture in Picture (PiP) mode. [betterPlayerGlobalKey] is required
  ///to open PiP mode in iOS. When device is not supported, PiP mode won't be
  ///open.
  Future<void>? enablePictureInPicture(GlobalKey betterPlayerGlobalKey) async {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }

    final bool isPipSupported =
        (await videoPlayerController!.isPictureInPictureSupported()) ?? false;

    if (isPipSupported) {
      _wasInFullScreenBeforePiP = _isFullScreen;
      _wasControlsEnabledBeforePiP = _controlsEnabled;
      setControlsEnabled(false);
      if (Platform.isAndroid) {
        _wasInFullScreenBeforePiP = _isFullScreen;
        await videoPlayerController?.enablePictureInPicture(
            left: 0, top: 0, width: 0, height: 0);
        enterFullScreen();
        _postEvent(YoYoPlayerEvent(YoYoPlayerEventType.pipStart));
        return;
      }
      if (Platform.isIOS) {
        final RenderBox? renderBox = betterPlayerGlobalKey.currentContext!
            .findRenderObject() as RenderBox?;
        if (renderBox == null) {
          YoYoPlayerUtils.log(
              "Can't show PiP. RenderBox is null. Did you provide valid global"
              " key?");
          return;
        }
        final Offset position = renderBox.localToGlobal(Offset.zero);
        return videoPlayerController?.enablePictureInPicture(
          left: position.dx,
          top: position.dy,
          width: renderBox.size.width,
          height: renderBox.size.height,
        );
      } else {
        YoYoPlayerUtils.log("Unsupported PiP in current platform.");
      }
    } else {
      YoYoPlayerUtils.log(
          "Picture in picture is not supported in this device. If you're "
          "using Android, please check if you're using activity v2 "
          "embedding.");
    }
  }

  ///Disable Picture in Picture mode if it's enabled.
  Future<void>? disablePictureInPicture() {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }
    return videoPlayerController!.disablePictureInPicture();
  }

  // ignore: use_setters_to_change_properties
  ///Set GlobalKey of BetterPlayer. Used in PiP methods called from controls.
  void setBetterPlayerGlobalKey(GlobalKey betterPlayerGlobalKey) {
    _yoyoPlayerGlobalKey = betterPlayerGlobalKey;
  }

  ///Check if picture in picture mode is supported in this device.
  Future<bool> isPictureInPictureSupported() async {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }

    final bool isPipSupported =
        (await videoPlayerController!.isPictureInPictureSupported()) ?? false;

    return isPipSupported && !_isFullScreen;
  }

  ///Handle VideoEvent when remote controls notification / PiP is shown
  void _handleVideoEvent(VideoEvent event) async {
    switch (event.eventType) {
      case VideoEventType.play:
        _postEvent(YoYoPlayerEvent(YoYoPlayerEventType.play));
        break;
      case VideoEventType.pause:
        _postEvent(YoYoPlayerEvent(YoYoPlayerEventType.pause));
        break;
      case VideoEventType.seek:
        _postEvent(YoYoPlayerEvent(YoYoPlayerEventType.seekTo));
        break;
      case VideoEventType.completed:
        final VideoPlayerValue? videoValue = videoPlayerController?.value;
        _postEvent(
          YoYoPlayerEvent(
            YoYoPlayerEventType.finished,
            parameters: <String, dynamic>{
              _progressParameter: videoValue?.position,
              _durationParameter: videoValue?.duration
            },
          ),
        );
        break;
      default:

        ///TODO: Handle when needed
        break;
    }
  }

  ///Setup controls always visible mode
  void setControlsAlwaysVisible(bool controlsAlwaysVisible) {
    _controlsAlwaysVisible = controlsAlwaysVisible;
    _controlsVisibilityStreamController.add(controlsAlwaysVisible);
  }

  ///Retry data source if playback failed.
  Future retryDataSource() async {
    await _setupDataSource(_yoyoPlayerDataSource!);
    if (_videoPlayerValueOnError != null) {
      final position = _videoPlayerValueOnError!.position;
      await seekTo(position);
      await play();
      _videoPlayerValueOnError = null;
    }
  }

  ///Set [audioTrack] in player. Works only for HLS streams.
  void setAudioTrack(YoYoPlayerHlsAudioTrack audioTrack) {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }

    if (audioTrack.language == null) {
      _yoyoPlayerHlsAudioTrack = null;
      return;
    }

    _yoyoPlayerHlsAudioTrack = audioTrack;
    videoPlayerController!.setAudioTrack(audioTrack.label, audioTrack.id);
  }

  ///Enable or disable audio mixing with other sound within device.
  void setMixWithOthers(bool mixWithOthers) {
    if (videoPlayerController == null) {
      throw StateError("The data source has not been initialized");
    }

    videoPlayerController!.setMixWithOthers(mixWithOthers);
  }

  ///Build headers map that will be used to setup video player controller. Apply
  ///DRM headers if available.
  Map<String, String?> _getHeaders() {
    final headers = yoyoPlayerDataSource!.headers ?? {};
    if (yoyoPlayerDataSource?.drmConfiguration?.drmType ==
            YoYoPlayerDrmType.token &&
        yoyoPlayerDataSource?.drmConfiguration?.token != null) {
      headers[_authorizationHeader] =
          yoyoPlayerDataSource!.drmConfiguration!.token!;
    }
    return headers;
  }

  /// Add controller internal event.
  void _postControllerEvent(YoYoPlayerControllerEvent event) {
    _controllerEventStreamController.add(event);
  }

  ///Dispose BetterPlayerController. When [forceDispose] parameter is true, then
  ///autoDispose parameter will be overridden and controller will be disposed
  ///(if it wasn't disposed before).
  void dispose({bool forceDispose = false}) {
    if (!yoyoPlayerConfiguration.autoDispose && !forceDispose) {
      return;
    }
    if (!_disposed) {
      pause();
      _eventListeners.clear();
      videoPlayerController?.removeListener(_onFullScreenStateChanged);
      videoPlayerController?.removeListener(_onVideoPlayerChanged);
      videoPlayerController?.dispose();
      _nextVideoTimer?.cancel();
      nextVideoTimeStreamController.close();
      _controlsVisibilityStreamController.close();
      _videoEventStreamSubscription?.cancel();
      _disposed = true;
      _controllerEventStreamController.close();

      ///Delete files async
      _tempFiles.forEach((file) => file.delete());
    }
  }
}
