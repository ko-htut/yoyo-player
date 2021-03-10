// Project imports:
import 'package:yoyo_player/src/configuration/yoyo_player_event_type.dart';

///Event that happens in player. It can be used to determine current player state
///on higher layer.
class YoYoPlayerEvent {
  final YoYoPlayerEventType yoyoPlayerEventType;
  final Map<String, dynamic>? parameters;

  YoYoPlayerEvent(this.yoyoPlayerEventType, {this.parameters});
}
