import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/constants.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoSection extends StatelessWidget {
  final String link;
  const VideoSection({super.key, required this.link});

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
      return const Text(
        "Video tidak valid",
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
          const Text(
            "Video Profile",
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
