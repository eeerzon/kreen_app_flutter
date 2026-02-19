

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class BackupTempPage extends StatefulWidget {
  final String link;
  final String headerText;
  final String noValidText;

  const BackupTempPage({
    super.key,
    required this.link,
    required this.headerText,
    required this.noValidText,
  });

  @override
  State<BackupTempPage> createState() => _BackupTempPageState();
}

class _BackupTempPageState extends State<BackupTempPage> {


  String extractVideoId(String url) {
    try {
      return YoutubePlayer.convertUrlToId(url) ?? "";
    } catch (_) {
      return "";
    }
  }

  YoutubePlayerController? _ytController;
  VideoPlayerController? _videoController;

  bool get _isYoutube =>
    widget.link.contains('youtube.com') ||
    widget.link.contains('youtu.be');

  @override
  void initState() {
    super.initState();

    if (_isYoutube) {
      final videoId = _extractYoutubeVideoId(widget.link);
      if (videoId != null) {
        _ytController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            enableCaption: true,
          ),
        );
      }
    } else {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.link),
      )..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _ytController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isYoutube && _ytController != null) {
      return _buildYoutubePlayer();
    }

    if (!_isYoutube && _videoController != null) {
      return _buildNormalVideo();
    }

    return const AspectRatio(
      aspectRatio: 16 / 9,
      child: Center(child: CircularProgressIndicator()),
    );
  }
  
  Widget _buildYoutubePlayer() {
    return YoutubePlayerBuilder(
      onEnterFullScreen: () async {
        final videoId = _ytController!.metadata.videoId;
        final seconds = _ytController!.value.position.inSeconds;

        final url =
            'https://www.youtube.com/watch?v=$videoId&t=${seconds}s';

        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      },
      onExitFullScreen: () {}, // ⛔ disable internal fullscreen
      player: YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
      ),
      builder: (context, player) => AspectRatio(
        aspectRatio: 16 / 9,
        child: player,
      ),
    );
  }
  
  Widget _buildNormalVideo() {
    if (!_videoController!.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_videoController!),
          IconButton(
            icon: Icon(
              _videoController!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              size: 48,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _videoController!.value.isPlaying
                    ? _videoController!.pause()
                    : _videoController!.play();
              });
            },
          ),
        ],
      ),
    );
  }
  
  String? _extractYoutubeVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // embed
    if (uri.pathSegments.contains('embed')) {
      return uri.pathSegments.last;
    }

    // watch?v=
    if (uri.queryParameters['v'] != null) {
      return uri.queryParameters['v'];
    }

    // youtu.be
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.first;
    }

    return null;
  }
}