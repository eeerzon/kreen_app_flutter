import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kreen_app_flutter/helper/yt_section_player.dart';
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
  bool _isOpeningFullscreen = false;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(() {
      if (widget.controller.value.isFullScreen) {
        widget.controller.toggleFullScreenMode();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      // cegah fullscreen default
      // onEnterFullScreen: () async {
      //   if (_isOpeningFullscreen) return; // 🔒 GUARD
      //     _isOpeningFullscreen = true;

      //   await Navigator.of(context).push(
      //     MaterialPageRoute(
      //       builder: (_) => FullscreenYoutubePage(
      //         controller: widget.controller,
      //       ),
      //     ),
      //   );

      //   _isOpeningFullscreen = false; // 🔓 RELEASE
      // },
      onEnterFullScreen: null, // cegah fullscreen default

      // kosongkan exit default
      // onExitFullScreen: () {},

      player: YoutubePlayer(
        controller: widget.controller,
        showVideoProgressIndicator: true,
      ),

      // JANGAN bungkus Column / Container
      builder: (context, player) => player,
    );
  }
}
