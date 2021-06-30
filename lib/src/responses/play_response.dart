import 'package:video_player/video_player.dart';

void fastForward({required VideoPlayerController controller}) {
  if (controller.value.duration.inSeconds -
          controller.value.position.inSeconds >
      10) {
    controller
        .seekTo(Duration(seconds: controller.value.position.inSeconds + 10));
  }
  if (!controller.value.isPlaying) {}
}

void rewind(VideoPlayerController controller) {
  if (controller.value.position.inSeconds > 10) {
    controller
        .seekTo(Duration(seconds: controller.value.position.inSeconds - 10));
  } else {
    controller.seekTo(Duration(seconds: 0));
  }
  if (!controller.value.isPlaying) {}
}
