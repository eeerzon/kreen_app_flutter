// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class FullscreenYoutubePage extends StatefulWidget {
  final YoutubePlayerController controller;

  const FullscreenYoutubePage({super.key, required this.controller});

  @override
  State<FullscreenYoutubePage> createState() =>
      _FullscreenYoutubePageState();
}

class _FullscreenYoutubePageState extends State<FullscreenYoutubePage> {
  late YoutubePlayerController _controller;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller.addListener(_fullscreenListener);
  }


  void _fullscreenListener() {
    if (_isPopping) return;

    if (!_controller.value.isFullScreen && mounted) {
      _isPopping = true;

      // ⛔ JANGAN pop langsung
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_fullscreenListener);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(
              controller: widget.controller,
              showVideoProgressIndicator: true,
            ),
          ),
        ),
      ),
    );
  }
}
