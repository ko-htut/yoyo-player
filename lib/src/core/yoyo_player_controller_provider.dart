// Flutter imports:
// Project imports:
import 'package:flutter/material.dart';

import '../../yoyo_player.dart';

///Widget which is used to inherit BetterPlayerController through widget tree.
class YoYoPlayerControllerProvider extends InheritedWidget {
  const YoYoPlayerControllerProvider({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  final YoYoPlayerController controller;

  @override
  bool updateShouldNotify(YoYoPlayerControllerProvider old) =>
      controller != old.controller;
}
