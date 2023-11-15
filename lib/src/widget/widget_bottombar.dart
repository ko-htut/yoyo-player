import 'package:flutter/material.dart';
import 'package:smooth_video_progress/smooth_video_progress.dart';
import 'package:video_player/video_player.dart';

Widget bottomBar({
  VideoPlayerController? controller,
  String? videoSeek,
  String? videoDuration,
  Widget? backwardIcon,
  Widget? forwardIcon,
  required bool showMenu,
  final playbackSpeed,
  Function? play,
  Function? forwrad,
  Function? rewind,
}) {
  String convertDurationToString(Duration duration) {
    var minutes = (duration.inMinutes % 60).toString();
    if (minutes.length == 1) {
      minutes = '0' + minutes;
    }
    var seconds = (duration.inSeconds % 60).toString();
    if (seconds.length == 1) {
      seconds = '0' + seconds;
    }
    var hour = (duration.inHours).toString();
    if (hour.length == 1) {
      hour = '0' + hour;
    }
    return "$hour:$minutes:$seconds";
  }

  return showMenu
      ? Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.grey.withOpacity(.5),
                borderRadius: BorderRadius.circular(10)),
            // padding: EdgeInsets.symmetric(vertical: 10),
            height: 100,
            child: Padding(
              padding: EdgeInsets.all(0.0),
              child: Stack(
                children: [
                  Column(
                    children: [
                      // if (controller!.value.isPlaying)
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: SmoothVideoProgress(
                          controller: controller!,
                          builder: (context, position, duration, child) =>
                              Directionality(
                            textDirection: TextDirection.ltr,
                            child: Slider(
                              onChangeStart: (_) => controller.pause(),
                              onChangeEnd: (_) => controller.play(),
                              onChanged: (value) => controller.seekTo(
                                  Duration(milliseconds: value.toInt())),
                              value: position.inMilliseconds.toDouble(),
                              divisions: duration.inSeconds,
                              // min: cu,
                              label: convertDurationToString(
                                  controller.value.position),

                              max: duration.inMilliseconds.toDouble(),
                            ),
                          ),
                        ),
                      ),
                      // VideoProgressIndicator(
                      //   controller,
                      //   allowScrubbing: true,
                      //   colors: VideoProgressColors(
                      //       playedColor: Colors
                      //           .blue), //Color.fromARGB(250, 0, 255, 112)),
                      //   padding:
                      //       EdgeInsets.only(left: 5.0, right: 5, bottom: 5),
                      // ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Padding(
                          padding: EdgeInsets.only(left: 5.0, right: 5.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                videoSeek!,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 17),
                              ),
                              Text(
                                videoDuration!,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 17),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          InkWell(
                              onTap: rewind as void Function()?,
                              child: backwardIcon),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: InkWell(
                              onTap: play as void Function()?,
                              child: Icon(
                                controller.value.isPlaying
                                    ? Icons.pause_circle_outline
                                    : Icons.play_circle_outline,
                                color: Colors.white,
                                size: 55,
                              ),
                            ),
                          ),
                          InkWell(
                              onTap: forwrad as void Function()?,
                              child: forwardIcon),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      : Container();
}
