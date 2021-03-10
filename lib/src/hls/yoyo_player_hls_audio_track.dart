///Representation of HLS audio track
class YoYoPlayerHlsAudioTrack {
  ///Id of track inside HLS playlist
  final int? id;

  ///Description of the audio
  final String? label;

  ///Language code
  final String? language;

  ///Url of audio track
  final String? url;

  YoYoPlayerHlsAudioTrack({this.id, this.label, this.language, this.url});
}
