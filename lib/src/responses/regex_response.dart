class RegexResponse {
  static String regexMAIN =
      "#EXT-X-STREAM-INF:(?:.*,RESOLUTION=(\d+x\d+))?:.*,\r?\n(.*)";
  static String regexMEDIA =
      r"""^#EXT-X-MEDIA:TYPE=AUDIO(?:.*,URI="(.*m3u8)")""";
  static String regexAUDIO = "";
  static String regexSUBTITLE = "";
  static String regexSRT =
      r"^((\d{2}):(\d{2}):(\d{2}),(\d{3})) +--> +((\d{2}):(\d{2}):(\d{2}),(\d{2})).*[\r\n]+\s*((?:(?!\r?\n\r?).)*)";
  static String regexASS = "";
  static String regexVTT = "";
  static String regexSTREAM = "";
  static String regexFILE = "";
  static String regexHTTP = r'^(http|https):\/\/([\w.]+\/?)\S*';
  static String regexURL = r'(.*)\r?\/';
}
