<h1 align="center">
  <a href="https://kohtut.dev"><img src="https://raw.githubusercontent.com/ko-htut/yoyo-player/master/yoyo_logo.png" alt="KoHtut"></a>
</h1>

# YoYo Video Player

YoYo Video Player is a HLS(.m3u8) video player for flutter.
The [video_player](https://pub.dev/packages/yoyo_player) is a video player that allows you to select HLS video streaming by selecting the quality. YoYo Player wraps `video_player` under the hood and provides base architecture for developers to create their own set of UI and functionalities.


# Features

* You can select multiple quality and open
* On video tap play/pause, mute/unmute, or perform any action on video.
* Auto hide controls.

## Usage

A simple usage example:

```dart
import 'package:yoyo_player/yoyo_player.dart';

 YoYoPlayer(
          rewind: Icons.skip_previous,
          fastForward: Icons.skip_next,
          aspectRatio: 16 / 9,
          fullscreen: Icons.fullscreen,
          play: Icons.play_arrow,
          pause: Icons.pause,
          url:
              "https://player.vimeo.com/external/440218055.m3u8?s=7ec886b4db9c3a52e0e7f5f917ba7287685ef67f&oauth2_token_id=1360367101",
          multipleaudioquality: true,
          deafultfullscreen: false,
        ),
```