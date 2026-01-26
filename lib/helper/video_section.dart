import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/constants.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoSection extends StatelessWidget {
  final String link;
  final String headerText;
  final String noValidText;
  const VideoSection({super.key, required this.link, required this.headerText, required this.noValidText});

  String extractVideoId(String url) {
    try {
      return YoutubePlayer.convertUrlToId(url) ?? "";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoId = extractVideoId(link);

    if (videoId.isEmpty) {
      return Text(
        noValidText,
        style: TextStyle(color: Colors.red),
      );
    }

    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );

    return Container(
      color: Colors.white,
      padding: kGlobalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            headerText,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          YoutubePlayer(
            controller: controller,
            showVideoProgressIndicator: true,
          )
        ],
      ),
    );
  }
}
