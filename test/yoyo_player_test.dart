import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:yoyo_player/yoyo_player.dart';

import 'yoyo_player_mock_controller.dart';
import 'yoyo_player_test_utils.dart';
import 'mock_method_channel.dart';

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    // ignore: unused_local_variable
    final MockMethodChannel mockMethodChannel = MockMethodChannel();
  });

  testWidgets("YoYo Player simple player - network",
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrapWidget(
        YoYoPlayer.network(YoYoPlayerTestUtils.bugBuckBunnyVideoUrl)));
    expect(find.byWidgetPredicate((widget) => widget is YoYoPlayer),
        findsOneWidget);
  });

  testWidgets("YoYo Player simple player - file", (WidgetTester tester) async {
    await tester.pumpWidget(_wrapWidget(
        YoYoPlayer.network(YoYoPlayerTestUtils.bugBuckBunnyVideoUrl)));
    expect(find.byWidgetPredicate((widget) => widget is YoYoPlayer),
        findsOneWidget);
  });

  testWidgets("YoYo Player - with controller", (WidgetTester tester) async {
    final YoYoPlayerMockController yoyoPlayerController =
        YoYoPlayerMockController(const YoYoPlayerConfiguration());
    await tester.pumpWidget(_wrapWidget(YoYoPlayer(
      controller: yoyoPlayerController,
    )));
    expect(find.byWidgetPredicate((widget) => widget is YoYoPlayer),
        findsOneWidget);
  });
}

///Wrap widget with material app to handle all features like navigation and
///localization properly.
Widget _wrapWidget(Widget widget) {
  return MaterialApp(home: widget);
}
