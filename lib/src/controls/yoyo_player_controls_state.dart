// Dart imports:
import 'dart:math';

// Flutter imports:
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:yoyo_player/src/core/yoyo_player_utils.dart';
import 'package:yoyo_player/src/hls/yoyo_player_hls_audio_track.dart';
import 'package:yoyo_player/src/hls/yoyo_player_hls_track.dart';

import '../../yoyo_player.dart';
import 'yoyo_player_clickable_widget.dart';

///Base class for both material and cupertino controls
abstract class YoYoPlayerControlsState<T extends StatefulWidget>
    extends State<T> {
  ///Min. time of buffered video to hide loading timer (in milliseconds)
  static const int _bufferingInterval = 20000;

  YoYoPlayerController? get yoyoPlayerController;

  YoYoPlayerControlsConfiguration get yoyoPlayerControlsConfiguration;

  VideoPlayerValue? get latestValue;

  void cancelAndRestartTimer();

  bool isVideoFinished(VideoPlayerValue? videoPlayerValue) {
    return videoPlayerValue?.position != null &&
        videoPlayerValue?.duration != null &&
        videoPlayerValue!.position.inMilliseconds != 0 &&
        videoPlayerValue.duration!.inMilliseconds != 0 &&
        videoPlayerValue.position >= videoPlayerValue.duration!;
  }

  void skipBack() {
    cancelAndRestartTimer();
    final beginning = const Duration().inMilliseconds;
    final skip = (latestValue!.position -
            Duration(
                milliseconds: yoyoPlayerControlsConfiguration
                    .backwardSkipTimeInMilliseconds))
        .inMilliseconds;
    yoyoPlayerController!.seekTo(Duration(milliseconds: max(skip, beginning)));
  }

  void skipForward() {
    cancelAndRestartTimer();
    final end = latestValue!.duration!.inMilliseconds;
    final skip = (latestValue!.position +
            Duration(
                milliseconds: yoyoPlayerControlsConfiguration
                    .forwardSkipTimeInMilliseconds))
        .inMilliseconds;
    yoyoPlayerController!.seekTo(Duration(milliseconds: min(skip, end)));
  }

  void onShowMoreClicked() {
    _showModalBottomSheet([_buildMoreOptionsList()]);
  }

  Widget _buildMoreOptionsList() {
    final translations = yoyoPlayerController!.translations;
    return SingleChildScrollView(
      // ignore: avoid_unnecessary_containers
      child: Container(
        child: Column(
          children: [
            if (yoyoPlayerControlsConfiguration.enablePlaybackSpeed)
              _buildMoreOptionsListRow(
                  yoyoPlayerControlsConfiguration.playbackSpeedIcon,
                  translations.overflowMenuPlaybackSpeed, () {
                Navigator.of(context).pop();
                _showSpeedChooserWidget();
              }),
            if (yoyoPlayerControlsConfiguration.enableSubtitles)
              _buildMoreOptionsListRow(
                  yoyoPlayerControlsConfiguration.subtitlesIcon,
                  translations.overflowMenuSubtitles, () {
                Navigator.of(context).pop();
                _showSubtitlesSelectionWidget();
              }),
            if (yoyoPlayerControlsConfiguration.enableQualities)
              _buildMoreOptionsListRow(
                  yoyoPlayerControlsConfiguration.qualitiesIcon,
                  translations.overflowMenuQuality, () {
                Navigator.of(context).pop();
                _showQualitiesSelectionWidget();
              }),
            if (yoyoPlayerControlsConfiguration.enableAudioTracks)
              _buildMoreOptionsListRow(
                  yoyoPlayerControlsConfiguration.audioTracksIcon,
                  translations.overflowMenuAudioTracks, () {
                Navigator.of(context).pop();
                _showAudioTracksSelectionWidget();
              }),
            if (yoyoPlayerControlsConfiguration
                .overflowMenuCustomItems.isNotEmpty)
              ...yoyoPlayerControlsConfiguration.overflowMenuCustomItems.map(
                (customItem) => _buildMoreOptionsListRow(
                  customItem.icon,
                  customItem.title,
                  () {
                    Navigator.of(context).pop();
                    customItem.onClicked.call();
                  },
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOptionsListRow(
      IconData icon, String name, void Function() onTap) {
    return YoYoPlayerMaterialClickableWidget(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: yoyoPlayerControlsConfiguration.overflowMenuIconsColor,
            ),
            const SizedBox(width: 16),
            Text(
              name,
              style: _getOverflowMenuElementTextStyle(false),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedChooserWidget() {
    _showModalBottomSheet([
      _buildSpeedRow(0.25),
      _buildSpeedRow(0.5),
      _buildSpeedRow(0.75),
      _buildSpeedRow(1.0),
      _buildSpeedRow(1.25),
      _buildSpeedRow(1.5),
      _buildSpeedRow(1.75),
      _buildSpeedRow(2.0),
    ]);
  }

  Widget _buildSpeedRow(double value) {
    final bool isSelected =
        yoyoPlayerController!.videoPlayerController!.value.speed == value;

    return YoYoPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        yoyoPlayerController!.setSpeed(value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              "$value x",
              style: _getOverflowMenuElementTextStyle(isSelected),
            )
          ],
        ),
      ),
    );
  }

  ///Latest value can be null
  bool isLoading(VideoPlayerValue? latestValue) {
    if (latestValue != null) {
      if (!latestValue.isPlaying && latestValue.duration == null) {
        return true;
      }

      final Duration position = latestValue.position;

      Duration? bufferedEndPosition;
      if (latestValue.buffered.isNotEmpty == true) {
        bufferedEndPosition = latestValue.buffered.last.end;
      }

      if (bufferedEndPosition != null) {
        final difference = bufferedEndPosition - position;

        if (latestValue.isPlaying &&
            latestValue.isBuffering &&
            difference.inMilliseconds < _bufferingInterval) {
          return true;
        }
      }
    }
    return false;
  }

  void _showSubtitlesSelectionWidget() {
    final subtitles =
        List.of(yoyoPlayerController!.yoyoPlayerSubtitlesSourceList);
    final noneSubtitlesElementExists = subtitles.firstWhereOrNull(
            (source) => source.type == YoYoPlayerSubtitlesSourceType.none) !=
        null;
    if (!noneSubtitlesElementExists) {
      subtitles.add(
          YoYoPlayerSubtitlesSource(type: YoYoPlayerSubtitlesSourceType.none));
    }

    _showModalBottomSheet(
        subtitles.map((source) => _buildSubtitlesSourceRow(source)).toList());
  }

  Widget _buildSubtitlesSourceRow(YoYoPlayerSubtitlesSource subtitlesSource) {
    final selectedSourceType = yoyoPlayerController!.yoyoPlayerSubtitlesSource;
    final bool isSelected = (subtitlesSource == selectedSourceType) ||
        (subtitlesSource.type == YoYoPlayerSubtitlesSourceType.none &&
            subtitlesSource.type == selectedSourceType!.type);

    return YoYoPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        yoyoPlayerController!.setupSubtitleSource(subtitlesSource);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              subtitlesSource.type == YoYoPlayerSubtitlesSourceType.none
                  ? yoyoPlayerController!.translations.generalNone
                  : subtitlesSource.name ??
                      yoyoPlayerController!.translations.generalDefault,
              style: _getOverflowMenuElementTextStyle(isSelected),
            ),
          ],
        ),
      ),
    );
  }

  ///Build both track and resolution selection
  ///Track selection is used for HLS videos
  ///Resolution selection is used for normal videos
  void _showQualitiesSelectionWidget() {
    final List<String> trackNames =
        yoyoPlayerController!.yoyoPlayerDataSource!.hlsTrackNames ?? [];
    final List<YoYoPlayerHlsTrack> tracks =
        yoyoPlayerController!.yoyoPlayerTracks;
    final List<Widget> children = [];
    for (var index = 0; index < tracks.length; index++) {
      final track = tracks[index];

      String? preferredName;
      if (track.height == 0 && track.width == 0 && track.bitrate == 0) {
        preferredName = yoyoPlayerController!.translations.qualityAuto;
      } else {
        preferredName = trackNames.length > index ? trackNames[index] : null;
      }
      children.add(_buildTrackRow(tracks[index], preferredName));
    }

    final resolutions = yoyoPlayerController!.yoyoPlayerDataSource!.resolutions;
    resolutions?.forEach((key, value) {
      children.add(_buildResolutionSelectionRow(key, value));
    });

    if (children.isEmpty) {
      children.add(
        _buildTrackRow(YoYoPlayerHlsTrack.defaultTrack(),
            yoyoPlayerController!.translations.qualityAuto),
      );
    }

    _showModalBottomSheet(children);
  }

  Widget _buildTrackRow(YoYoPlayerHlsTrack track, String? preferredName) {
    final String trackName = preferredName ??
        "${track.width}x${track.height} ${YoYoPlayerUtils.formatBitrate(track.bitrate!)}";

    final selectedTrack = yoyoPlayerController!.yoyoPlayerTrack;
    final bool isSelected = selectedTrack != null && selectedTrack == track;

    return YoYoPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        yoyoPlayerController!.setTrack(track);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              trackName,
              style: _getOverflowMenuElementTextStyle(isSelected),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionSelectionRow(String name, String url) {
    final bool isSelected =
        url == yoyoPlayerController!.yoyoPlayerDataSource!.url;
    return YoYoPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        yoyoPlayerController!.setResolution(url);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              name,
              style: _getOverflowMenuElementTextStyle(isSelected),
            ),
          ],
        ),
      ),
    );
  }

  void _showAudioTracksSelectionWidget() {
    final List<YoYoPlayerHlsAudioTrack>? tracks =
        yoyoPlayerController!.betterPlayerAudioTracks;
    final List<Widget> children = [];
    final YoYoPlayerHlsAudioTrack? selectedAudioTrack =
        yoyoPlayerController!.yoyoPlayerAudioTrack;
    if (tracks != null) {
      for (var index = 0; index < tracks.length; index++) {
        final bool isSelected =
            selectedAudioTrack != null && selectedAudioTrack == tracks[index];
        children.add(_buildAudioTrackRow(tracks[index], isSelected));
      }
    }

    if (children.isEmpty) {
      children.add(
        _buildAudioTrackRow(
          YoYoPlayerHlsAudioTrack(
            label: yoyoPlayerController!.translations.generalDefault,
          ),
          true,
        ),
      );
    }

    _showModalBottomSheet(children);
  }

  Widget _buildAudioTrackRow(
      YoYoPlayerHlsAudioTrack audioTrack, bool isSelected) {
    return YoYoPlayerMaterialClickableWidget(
      onTap: () {
        Navigator.of(context).pop();
        yoyoPlayerController!.setAudioTrack(audioTrack);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Text(
              audioTrack.label!,
              style: _getOverflowMenuElementTextStyle(isSelected),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _getOverflowMenuElementTextStyle(bool isSelected) {
    return TextStyle(
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      color: yoyoPlayerControlsConfiguration.overflowModalTextColor,
    );
  }

  void _showModalBottomSheet(List<Widget> children) {
    showModalBottomSheet<void>(
      backgroundColor: yoyoPlayerControlsConfiguration.overflowModalColor,
      context: context,
      builder: (context) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              children: children,
            ),
          ),
        );
      },
    );
  }
}
