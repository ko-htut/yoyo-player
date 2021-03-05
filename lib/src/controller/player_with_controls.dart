import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:yoyo_player/src/controller/yoyo_controll.dart';
import 'package:yoyo_player/src/controller/yoyo_controller.dart';

class PlayerWithControls extends StatelessWidget {
  const PlayerWithControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final YoYoController yoyoController = YoYoController.of(context);

    double _calculateAspectRatio(BuildContext context) {
      final size = MediaQuery.of(context).size;
      final width = size.width;
      final height = size.height;

      return width > height ? width / height : height / width;
    }

    Widget _buildControls(
      BuildContext context,
      YoYoController yoyoController,
    ) {
      final controls = CupertinoControls(
        backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
        iconColor: Color.fromARGB(255, 200, 200, 200),
      );
      return yoyoController.showControls
          ? yoyoController.customControls ?? controls
          : Container();
    }

    Stack _buildPlayerWithControls(
        YoYoController llkController, BuildContext context) {
      return Stack(
        children: <Widget>[
          llkController.placeholder ?? Container(),
          Center(
            child: AspectRatio(
              aspectRatio: yoyoController.aspectRatio ??
                  yoyoController.videoPlayerController.value.aspectRatio,
              child: VideoPlayer(yoyoController.videoPlayerController),
            ),
          ),
          llkController.overlay ?? Container(),
          if (!llkController.isFullScreen)
            _buildControls(context, llkController)
          else
            SafeArea(
              child: _buildControls(context, llkController),
            ),
        ],
      );
    }

    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: AspectRatio(
          aspectRatio: _calculateAspectRatio(context),
          child: _buildPlayerWithControls(yoyoController, context),
        ),
      ),
    );
  }
}
