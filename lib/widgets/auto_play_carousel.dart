import 'dart:async';

import 'package:flutter/material.dart';

class AutoPlayCarousel extends StatefulWidget {
  final List<String> images;
  final List<double?> aspectRatios;

  const AutoPlayCarousel({
    super.key,
    required this.images,
    required this.aspectRatios,
  });

  @override
  State<AutoPlayCarousel> createState() => _AutoPlayCarouselState();
}

class _AutoPlayCarouselState extends State<AutoPlayCarousel> {
  late PageController controller;
  int currentIndex = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    controller = PageController();

    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (currentIndex + 1) % widget.images.length;
      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final aspect = widget.aspectRatios[currentIndex];
    final height = aspect == null ? 150 : (screenWidth / aspect);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red,
            Colors.white
          ],
          stops: [0.5, 0.5],
        )
      ),
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(vertical: 0, horizontal: 20),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          curve: Curves.easeOut,
          height: height as double,
          child: PageView.builder(
            controller: controller,
            onPageChanged: (i) => setState(() => currentIndex = i),
            itemCount: widget.images.length,
            itemBuilder: (context, i) {
              final img = widget.images[i];

              if (widget.aspectRatios[i] == null) {
                return Container(
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  img,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Container(
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
