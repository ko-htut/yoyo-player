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
    Function? play}) {
  return showMenu
      ? Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 40,
            child: Padding(
              padding: EdgeInsets.all(0.0),
              child: Stack(
                children: [
                  Column(
                    children: [
                      VideoProgressIndicator(
                        controller!,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                            playedColor: Color.fromARGB(250, 0, 255, 112)),
                        padding: EdgeInsets.only(left: 5.0, right: 5),
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
                                  color: Colors.white),
                            ),
                            Text(
                              videoDuration!,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.all(5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          InkWell(
                              onTap: () {
                                rewind(controller);
                              },
                              child: backwardIcon),
                          InkWell(
                            onTap: play as void Function()?,
                            child: Icon(
                              controller.value.isPlaying
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                          InkWell(
                              onTap: () {
                                fastForward(controller: controller);
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
