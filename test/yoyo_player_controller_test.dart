import 'package:flutter_test/flutter_test.dart';
import 'package:yoyo_player/yoyo_player.dart';
import 'yoyo_player_mock_controller.dart';
import 'yoyo_player_test_utils.dart';
import 'mock_method_channel.dart';

MockMethodChannel? mockMethodChannel;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    "Controller tests",
    () {
      setUpAll(() {
        mockMethodChannel = MockMethodChannel();
      });
      test("YoYoPlayerController - create without data source", () {
        final YoYoPlayerMockController yoyoPlayerMockController =
            YoYoPlayerMockController(const YoYoPlayerConfiguration());
        expect(yoyoPlayerMockController.yoyoPlayerDataSource, null);
        expect(yoyoPlayerMockController.videoPlayerController, null);
      });

      test("YoYoPlayerController - setup data source", () async {
        final YoYoPlayerMockController yoyoPlayerMockController =
            YoYoPlayerMockController(const YoYoPlayerConfiguration());
        await yoyoPlayerMockController.setupDataSource(
            YoYoPlayerDataSource.network(
                YoYoPlayerTestUtils.forBiggerBlazesUrl));
        expect(yoyoPlayerMockController.yoyoPlayerDataSource != null, true);
        expect(yoyoPlayerMockController.videoPlayerController != null, true);
      });

      test(
        "YoYoPlayerController - play should change isPlaying flag",
        () async {
          final YoYoPlayerController yoyoPlayerController =
              YoYoPlayerController(const YoYoPlayerConfiguration(),
                  yoyoPlayerDataSource: YoYoPlayerDataSource.network(
                      YoYoPlayerTestUtils.forBiggerBlazesUrl));
          yoyoPlayerController.play();
          expect(yoyoPlayerController.isPlaying(), true);
        },
      );

      test(
        "YoYoPlayerController - pause should change isPlaying flag",
        () async {
          final YoYoPlayerController betterPlayerController =
              YoYoPlayerController(const YoYoPlayerConfiguration(),
                  yoyoPlayerDataSource: YoYoPlayerDataSource.network(
                      YoYoPlayerTestUtils.forBiggerBlazesUrl));
          betterPlayerController.play();
          expect(betterPlayerController.isPlaying(), true);
          betterPlayerController.pause();
          expect(betterPlayerController.isPlaying(), false);
        },
      );

      test("YoYoPlayerController - full screen and auto play should work",
          () async {
        final YoYoPlayerMockController yoyoPlayerMockController =
            YoYoPlayerMockController(const YoYoPlayerConfiguration(
                fullScreenByDefault: true, autoPlay: true));
        await yoyoPlayerMockController.setupDataSource(
            YoYoPlayerDataSource.network(
                YoYoPlayerTestUtils.forBiggerBlazesUrl));
        expect(yoyoPlayerMockController.isFullScreen, true);
        expect(yoyoPlayerMockController.isPlaying(), true);
      });
    },
  );
}
