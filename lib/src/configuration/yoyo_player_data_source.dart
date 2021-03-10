// Project imports:
import 'package:flutter/widgets.dart';
import 'package:yoyo_player/src/configuration/yoyo_player_notification_configuration.dart';

import '../../yoyo_player.dart';
import 'yoyo_player_cache_configuration.dart';

///Representation of data source which will be played in Better Player. Allows
///to setup all necessary configuration connected to video source.
class YoYoPlayerDataSource {
  ///Type of source of video
  final YoYoPlayerDataSourceType type;

  ///Url of the video
  final String url;

  ///Subtitles configuration
  final List<YoYoPlayerSubtitlesSource>? subtitles;

  ///Flag to determine if current data source is live stream
  final bool? liveStream;

  /// Custom headers for player
  final Map<String, String>? headers;

  ///Should player use hls subtitles
  final bool? useHlsSubtitles;

  ///Should player use hls tracks
  final bool? useHlsTracks;

  ///Should player use hls audio tracks
  final bool? useHlsAudioTracks;

  ///List of strings that represents tracks names.
  ///If empty, then better player will choose name based on track parameters
  final List<String>? hlsTrackNames;

  ///Optional, alternative resolutions for non-hls video. Used to setup
  ///different qualities for video.
  ///Data should be in given format:
  ///{"360p": "url", "540p": "url2" }
  final Map<String, String>? resolutions;

  ///Optional cache configuration, used only for network data sources
  final YoYoPlayerCacheConfiguration? cacheConfiguration;

  ///List of bytes, used only in memory player
  final List<int>? bytes;

  ///Configuration of remote controls notification
  final YoYoPlayerNotificationConfiguration? notificationConfiguration;

  ///Duration which will be returned instead of original duration
  final Duration? overriddenDuration;

  ///Video format hint when data source url has not valid extension.
  final YoYoPlayerVideoFormat? videoFormat;

  ///Extension of video without dot. Used only in memory data source.
  final String? videoExtension;

  ///Configuration of content protection
  final YoYoPlayerDrmConfiguration? drmConfiguration;

  ///Placeholder widget which will be shown until video load or play. This
  ///placeholder may be useful if you want to show placeholder before each video
  ///in playlist. Otherwise, you should use placeholder from
  /// BetterPlayerConfiguration.
  final Widget? placeholder;

  YoYoPlayerDataSource(
    this.type,
    this.url, {
    this.bytes,
    this.subtitles,
    this.liveStream = false,
    this.headers,
    this.useHlsSubtitles = true,
    this.useHlsTracks = true,
    this.useHlsAudioTracks = true,
    this.hlsTrackNames,
    this.resolutions,
    this.cacheConfiguration,
    this.notificationConfiguration =
        const YoYoPlayerNotificationConfiguration(showNotification: false),
    this.overriddenDuration,
    this.videoFormat,
    this.videoExtension,
    this.drmConfiguration,
    this.placeholder,
  }) : assert(
            (type == YoYoPlayerDataSourceType.network ||
                    type == YoYoPlayerDataSourceType.file) ||
                (type == YoYoPlayerDataSourceType.memory &&
                    bytes?.isNotEmpty == true),
            "Url can't be null in network or file data source | bytes can't be null when using memory data source");

  ///Factory method to build network data source which uses url as data source
  ///Bytes parameter is not used in this data source.
  factory YoYoPlayerDataSource.network(
    String url, {
    List<YoYoPlayerSubtitlesSource>? subtitles,
    bool? liveStream,
    Map<String, String>? headers,
    bool? useHlsSubtitles,
    bool? useHlsTracks,
    bool? useHlsAudioTracks,
    Map<String, String>? qualities,
    YoYoPlayerCacheConfiguration? cacheConfiguration,
    YoYoPlayerNotificationConfiguration notificationConfiguration =
        const YoYoPlayerNotificationConfiguration(showNotification: false),
    Duration? overriddenDuration,
    YoYoPlayerVideoFormat? videoFormat,
    YoYoPlayerDrmConfiguration? drmConfiguration,
    Widget? placeholder,
  }) {
    return YoYoPlayerDataSource(
      YoYoPlayerDataSourceType.network,
      url,
      subtitles: subtitles,
      liveStream: liveStream,
      headers: headers,
      useHlsSubtitles: useHlsSubtitles,
      useHlsTracks: useHlsTracks,
      useHlsAudioTracks: useHlsAudioTracks,
      resolutions: qualities,
      cacheConfiguration: cacheConfiguration,
      notificationConfiguration: notificationConfiguration,
      overriddenDuration: overriddenDuration,
      videoFormat: videoFormat,
      drmConfiguration: drmConfiguration,
      placeholder: placeholder,
    );
  }

  ///Factory method to build file data source which uses url as data source.
  ///Bytes parameter is not used in this data source.
  factory YoYoPlayerDataSource.file(
    String url, {
    List<YoYoPlayerSubtitlesSource>? subtitles,
    bool? useHlsSubtitles,
    bool? useHlsTracks,
    Map<String, String>? qualities,
    YoYoPlayerCacheConfiguration? cacheConfiguration,
    YoYoPlayerNotificationConfiguration? notificationConfiguration,
    Duration? overriddenDuration,
    Widget? placeholder,
  }) {
    return YoYoPlayerDataSource(
      YoYoPlayerDataSourceType.file,
      url,
      subtitles: subtitles,
      useHlsSubtitles: useHlsSubtitles,
      useHlsTracks: useHlsTracks,
      resolutions: qualities,
      cacheConfiguration: cacheConfiguration,
      notificationConfiguration: notificationConfiguration =
          const YoYoPlayerNotificationConfiguration(showNotification: false),
      overriddenDuration: overriddenDuration,
      placeholder: placeholder,
    );
  }

  ///Factory method to build network data source which uses bytes as data source.
  ///Url parameter is not used in this data source.
  factory YoYoPlayerDataSource.memory(
    List<int> bytes, {
    String? videoExtension,
    List<YoYoPlayerSubtitlesSource>? subtitles,
    bool? useHlsSubtitles,
    bool? useHlsTracks,
    Map<String, String>? qualities,
    YoYoPlayerCacheConfiguration? cacheConfiguration,
    YoYoPlayerNotificationConfiguration? notificationConfiguration,
    Duration? overriddenDuration,
    Widget? placeholder,
  }) {
    return YoYoPlayerDataSource(
      YoYoPlayerDataSourceType.memory,
      "",
      videoExtension: videoExtension,
      bytes: bytes,
      subtitles: subtitles,
      useHlsSubtitles: useHlsSubtitles,
      useHlsTracks: useHlsTracks,
      resolutions: qualities,
      cacheConfiguration: cacheConfiguration,
      notificationConfiguration: notificationConfiguration =
          const YoYoPlayerNotificationConfiguration(showNotification: false),
      overriddenDuration: overriddenDuration,
      placeholder: placeholder,
    );
  }

  YoYoPlayerDataSource copyWith({
    YoYoPlayerDataSourceType? type,
    String? url,
    List<int>? bytes,
    List<YoYoPlayerSubtitlesSource>? subtitles,
    bool? liveStream,
    Map<String, String>? headers,
    bool? useHlsSubtitles,
    bool? useHlsTracks,
    bool? useHlsAudioTracks,
    Map<String, String>? resolutions,
    YoYoPlayerCacheConfiguration? cacheConfiguration,
    YoYoPlayerNotificationConfiguration? notificationConfiguration =
        const YoYoPlayerNotificationConfiguration(showNotification: false),
    Duration? overriddenDuration,
    YoYoPlayerVideoFormat? videoFormat,
    String? videoExtension,
    YoYoPlayerDrmConfiguration? drmConfiguration,
    Widget? placeholder,
  }) {
    return YoYoPlayerDataSource(
      type ?? this.type,
      url ?? this.url,
      bytes: bytes ?? this.bytes,
      subtitles: subtitles ?? this.subtitles,
      liveStream: liveStream ?? this.liveStream,
      headers: headers ?? this.headers,
      useHlsSubtitles: useHlsSubtitles ?? this.useHlsSubtitles,
      useHlsTracks: useHlsTracks ?? this.useHlsTracks,
      useHlsAudioTracks: useHlsAudioTracks ?? this.useHlsAudioTracks,
      resolutions: resolutions ?? this.resolutions,
      cacheConfiguration: cacheConfiguration ?? this.cacheConfiguration,
      notificationConfiguration:
          notificationConfiguration ?? this.notificationConfiguration,
      overriddenDuration: overriddenDuration ?? this.overriddenDuration,
      videoFormat: videoFormat ?? this.videoFormat,
      videoExtension: videoExtension ?? this.videoExtension,
      drmConfiguration: drmConfiguration ?? this.drmConfiguration,
      placeholder: placeholder ?? this.placeholder,
    );
  }
}
