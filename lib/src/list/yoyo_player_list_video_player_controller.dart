// Project imports:
import 'package:yoyo_player/yoyo_player.dart';

///Controller of Better Player List Video Player.
class YoYoPlayerListVideoPlayerController {
  YoYoPlayerController? _yoyoPlayerController;

  void setVolume(double volume) {
    _yoyoPlayerController?.setVolume(volume);
  }

  void pause() {
    _yoyoPlayerController?.pause();
  }

  void play() {
    _yoyoPlayerController?.play();
  }

  void seekTo(Duration duration) {
    _yoyoPlayerController?.seekTo(duration);
  }

  // ignore: use_setters_to_change_properties
  void setBetterPlayerController(YoYoPlayerController? yoyoPlayerController) {
    _yoyoPlayerController = yoyoPlayerController;
  }
}
