import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

Widget bottomBar(
  VideoPlayerController controller,
  String videoSeek,
  String videoDuration,
) {
  return Align(
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
                  controller,
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
                        videoSeek,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        videoDuration,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
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
                  children: [
                    Icon(
                      Icons.skip_previous,
                      color: Colors.white,
                    ),
                    Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                    ),
                    Icon(
                      Icons.skip_next,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
