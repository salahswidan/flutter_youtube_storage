import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PlayVideo extends StatefulWidget {
  String videoId;
  PlayVideo({required this.videoId});

  @override
  State<PlayVideo> createState() => _PlayVideoState();
}

class _PlayVideoState extends State<PlayVideo> {
  late YoutubePlayerController controller;
  @override
  void initState() {
    controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        loop: false,
        autoPlay: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Play Video"),
      ),
      body: YoutubePlayer(controller: controller,
      onReady: () => print('Player is ready.'),
      onEnded: (metaData) => print('Player ended.'),),
    );
  }
}
 