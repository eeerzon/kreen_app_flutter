import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoSection extends StatefulWidget {
  final YoutubePlayerController controller;

  const VideoSection({
    super.key,
    required this.controller,
  });

  @override
  State<VideoSection> createState() => _VideoSectionState();
}

class _VideoSectionState extends State<VideoSection> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant VideoSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      
      onEnterFullScreen: null,

      player: YoutubePlayer(
        controller: widget.controller,
        showVideoProgressIndicator: true,
        bottomActions: [
          CurrentPosition(),
          ProgressBar(isExpanded: true),
          RemainingDuration(),
        ],
      ),
      
      builder: (context, player) => player,
    );
  }
}
