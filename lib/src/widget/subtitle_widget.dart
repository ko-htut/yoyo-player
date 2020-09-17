// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:yoyo_player/src/model/subtitle.dart';

// Widget subtitleplay(
//     {VideoPlayerController controller, showSubtitles, Subtitle subtitle}) {
//   return showSubtitles
//       ? Container(
//           decoration: BoxDecoration(
//               color: Colors.grey.withOpacity(50),
//               borderRadius: BorderRadius.circular(5)),
//           child: Padding(
//             padding: const EdgeInsets.all(2.0),
//             child: Text(
//               controller.value.initialized
//                   ? subtitle != null ? subtitle.text : ""
//                   : "",
//               style: TextStyle(),
//             ),
//           ),
//         )
//       : Container(
//           child: Text("no subtitle"),
//         );
// }
