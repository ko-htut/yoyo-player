import '../../yoyo_player.dart';

///Configuration of DRM used to protect data source
class YoYoPlayerDrmConfiguration {
  ///Type of DRM
  final YoYoPlayerDrmType? drmType;

  ///Parameter used only for token encrypted DRMs
  final String? token;

  ///Url of license server, used only for WIDEVINE/PLAYREADY DRM
  final String? licenseUrl;

  ///Additional headers send with auth request, used only for WIDEVINE DRM
  final Map<String, String>? headers;

  YoYoPlayerDrmConfiguration({
    this.drmType,
    this.token,
    this.licenseUrl,
    this.headers,
  });
}
