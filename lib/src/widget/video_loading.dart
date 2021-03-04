import 'package:flutter/material.dart';

class VideoLoading extends StatelessWidget {
  const VideoLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: new AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
            SizedBox(height: 10),
            Text('Loading...')
          ],
        ),
      ),
    );
  }
}
