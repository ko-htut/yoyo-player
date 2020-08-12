<h1 align="center">
  <a href="https://kohtut.dev/2020/08/05/yo-yo-player/"><img src="https://raw.githubusercontent.com/ko-htut/yoyo-player/master/yoyo_logo.png" alt="KoHtut"></a>
</h1>

# YoYo Video Player

YoYo Video Player is a HLS(.m3u8) video player for flutter.
The [video_player](https://pub.dev/packages/yoyo_player) is a video player that allows you to select HLS video streaming by selecting the quality. YoYo Player wraps `video_player` under the hood and provides base architecture for developers to create their own set of UI and functionalities.

![Pub Version (including pre-releases)](https://img.shields.io/pub/v/yoyo_player)  !

# Features

* You can select multiple quality and open
* On video tap play/pause, mute/unmute, or perform any action on video.
* Auto hide controls.
* (.srt) Video Subtitle Support
* (.m3u8) HLS Video Streaming Support

## Install & Set up

1. Add dependency, open the root directory `pubspec.yaml`File in`dependencies:`Add the following code below

 ```yaml
 yoyo_player: #latest
 ```

2. Installation dependencies (please ignore if it has been installed automatically)

```dart
 cd Project directory
 flutter packages get
 ```

3. Introduce the library in the page

```dart
import 'package:yoyo_player/yoyo_player.dart';
```
## Usage

A simple usage example:

```dart
YoYoPlayer(
          aspectRatio: 16 / 9,
          url:  "",
          videoStyle: VideoStyle(),
          videoLoadingStyle: VideoLoadingStyle(),
        ),
```

Change Icon

```dart
 videoStyle: VideoStyle(
    play : Icon(Icons.play_arrow),
    pause : Icon(Icons.pause),
    fullscreen : Icon(Icon(Icons.fullscreen)),
    forward : Icon(Icons.skip_next),
    backward : Icon(Icons.skip_previous),
 )
```

Change Video Loading
```dart
 videoLoadingStyle: VideoLoadingStyle(loading : Center(child: Text("Loading video")),
```

Play With Subtitle
```dart
        body: YoYoPlayer(
          aspectRatio: 16 / 9,
          //url ( .m3u8 video streaming link )
          //example ( url :"https://sfux-ext.sfux.info/hls/chapter/105/1588724110/1588724110.m3u8" )
          //example ( url :"https://player.vimeo.com/external/440218055.m3u8?s=7ec886b4db9c3a52e0e7f5f917ba7287685ef67f&oauth2_token_id=1360367101" )
          url:  " ",
          videoStyle: VideoStyle(),
          videoLoadingStyle: VideoLoadingStyle(
            loading: Center(
              child: Text("Loading video"),
            ),
          ),
          //subtitle ( ...srt subtitle link )
          //example ( subtitle:"https://eboxmovie.sgp1.digitaloceanspaces.com/mmmmtest.srt")
          subtitle: "",
          // subtitle style
          subtitleStyle: SubtitleStyle(),
        ),
```

# Player Option

## Player

| Attributes        | Type                | Description                                |
|-------------------|---------------------|--------------------------------------------|
| url               | String              | Video source  ( .m3u8 & File only)         |
| subtitle   Î      | String              | Subtitle (.srt)o source                    |
| videoStyle        | VideoStyle          | Video Player  style                        |
| videoLoadingStyle | VideoLoadingStyle   | Video Loading Style                        |
| aspectRatio       | double              | Video AspectRaitio [aspectRatio : 16 / 9 ] |
| subtitleStyle     | SubtitleStyle       | Video Subtitle Style                       |
| onfullscreen      | VideoCallback<bool> | video state fullscreen                     |


## Player custom style (VideoStyle)

| Attributes   | Type      | Description                         |
|--------------|-----------|-------------------------------------|
| play         | Widget    | You can use any Widget you want     |
| pause        | Widget    | You can use any Widget you want     |
| fullscreen   | Widget    | You can use any Widget you want     |
| forward      | Widget    | You can use any Widget you want     |
| backward     | Widget    | You can use any Widget you want     |
| playedColor  | Color     | You can use any Icon style you want |
| qualitystyle | TextStyle | You can use any Text style you want |
| qashowstyle  | TextStyle | You can use any Text style you want |

## Player Loading custom style (VideoStyle)

| Attributes | Type   | Description                            |
|------------|--------|----------------------------------------|
| loading    | Widget | You can use any loading style you want |

## Subtitle Style
| Attributes | Type       | Description                             |
|------------|------------|-----------------------------------------|
| fontweight | FontWeight | You can use any Subtitle style you want |
| colors     | Color      | You can use any Subtitle style you want |
| background | Color      | You can use any Subtitle style you want |
| fontSize   | double     | You can use any Subtitle style you want |


# MIT License

Copyright (c) 2020 Ko Htut (Ko Min Than Htut)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.