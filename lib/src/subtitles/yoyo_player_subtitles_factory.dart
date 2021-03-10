// Dart imports:
import 'dart:convert';
import 'dart:io';
import 'package:yoyo_player/src/core/yoyo_player_utils.dart';
import '../../yoyo_player.dart';
import 'yoyo_player_subtitle.dart';
import 'yoyo_player_subtitles_source_type.dart';

class YoYoPlayerSubtitlesFactory {
  static Future<List<YoYoPlayerSubtitle>> parseSubtitles(
      YoYoPlayerSubtitlesSource source) async {
    switch (source.type) {
      case YoYoPlayerSubtitlesSourceType.file:
        return _parseSubtitlesFromFile(source);
      case YoYoPlayerSubtitlesSourceType.network:
        return _parseSubtitlesFromNetwork(source);
      case YoYoPlayerSubtitlesSourceType.memory:
        return _parseSubtitlesFromMemory(source);
      default:
        return [];
    }
  }

  static Future<List<YoYoPlayerSubtitle>> _parseSubtitlesFromFile(
      YoYoPlayerSubtitlesSource source) async {
    try {
      final List<YoYoPlayerSubtitle> subtitles = [];
      for (final String? url in source.urls!) {
        final file = File(url!);
        if (file.existsSync()) {
          final String fileContent = await file.readAsString();
          final subtitlesCache = _parseString(fileContent);
          subtitles.addAll(subtitlesCache);
        } else {
          YoYoPlayerUtils.log("$url doesn't exist!");
        }
      }
      return subtitles;
    } catch (exception) {
      YoYoPlayerUtils.log("Failed to read subtitles from file: $exception");
    }
    return [];
  }

  static Future<List<YoYoPlayerSubtitle>> _parseSubtitlesFromNetwork(
      YoYoPlayerSubtitlesSource source) async {
    try {
      final client = HttpClient();
      final List<YoYoPlayerSubtitle> subtitles = [];
      for (final String? url in source.urls!) {
        final request = await client.getUrl(Uri.parse(url!));
        final response = await request.close();
        final data = await response.transform(const Utf8Decoder()).join();
        final cacheList = _parseString(data);
        subtitles.addAll(cacheList);
      }
      client.close();

      YoYoPlayerUtils.log("Parsed total subtitles: ${subtitles.length}");
      return subtitles;
    } catch (exception) {
      YoYoPlayerUtils.log("Failed to read subtitles from network: $exception");
    }
    return [];
  }

  static List<YoYoPlayerSubtitle> _parseSubtitlesFromMemory(
      YoYoPlayerSubtitlesSource source) {
    try {
      return _parseString(source.content!);
    } catch (exception) {
      YoYoPlayerUtils.log("Failed to read subtitles from memory: $exception");
    }
    return [];
  }

  static List<YoYoPlayerSubtitle> _parseString(String value) {
    List<String> components = value.split('\r\n\r\n');
    if (components.length == 1) {
      components = value.split('\n\n');
    }

    final List<YoYoPlayerSubtitle> subtitlesObj = [];

    final bool isWebVTT = components.contains("WEBVTT");
    for (final component in components) {
      if (component.isEmpty) {
        continue;
      }
      final subtitle = YoYoPlayerSubtitle(component, isWebVTT);
      if (subtitle.start != null &&
          subtitle.end != null &&
          subtitle.texts != null) {
        subtitlesObj.add(subtitle);
      }
    }

    return subtitlesObj;
  }
}
