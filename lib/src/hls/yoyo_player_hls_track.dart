/// Represents HLS track which can be played within player
class YoYoPlayerHlsTrack {
  ///Width in px of the track
  final int? width;

  ///Height in px of the track
  final int? height;

  ///Bitrate in px of the track
  final int? bitrate;

  YoYoPlayerHlsTrack(this.width, this.height, this.bitrate);

  factory YoYoPlayerHlsTrack.defaultTrack() {
    return YoYoPlayerHlsTrack(0, 0, 0);
  }

  @override
  // ignore: unnecessary_overrides
  int get hashCode => super.hashCode;

  @override
  bool operator ==(dynamic other) {
    return other is YoYoPlayerHlsTrack &&
        width == other.width &&
        height == other.height &&
        bitrate == other.bitrate;
  }
}
