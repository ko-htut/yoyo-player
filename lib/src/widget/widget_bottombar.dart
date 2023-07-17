import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:yoyo_player/src/responses/play_response.dart';

Widget bottomBar(
    {VideoPlayerController? controller,
    String? videoSeek,
    String? videoDuration,
    Widget? backwardIcon,
    Widget? forwardIcon,
    required bool showMenu,
    final playbackSpeed,
    Function? play}) {
  return showMenu
      ? Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.grey.withOpacity(.5),
                borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.symmetric(vertical: 10),
            height: 90,
            child: Padding(
              padding: EdgeInsets.all(0.0),
              child: Stack(
                children: [
                  Column(
                    children: [
                      if (controller!.value.isPlaying)
                        // CupertinoSlider(
                        //   value: 0.0,
                        //   min: double.tryParse(
                        //       controller.value.duration.toString())!,
                        //   onChanged: (value) {},
                        // ),
                        VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                              playedColor: Colors
                                  .blue), //Color.fromARGB(250, 0, 255, 112)),
                          padding:
                              EdgeInsets.only(left: 5.0, right: 5, bottom: 5),
                        ),
                      Padding(
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
                              onTap: () {
                                rewind(controller);
                                controller.setPlaybackSpeed(playbackSpeed);
                              },
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
                              onTap: () {
                                fastForward(controller: controller);
                                controller.setPlaybackSpeed(playbackSpeed);
                              },
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
