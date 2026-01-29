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

    // viewportFraction bikin before-after peek
    controller = PageController(viewportFraction: 0.88);

    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (currentIndex + 1) % widget.images.length;
      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
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
    final height = aspect == null ? 150.0 : (screenWidth / aspect);

    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.red, Colors.white],
              stops: [0.5, 0.5],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              height: height,
              child: PageView.builder(
                controller: controller,
                onPageChanged: (i) => setState(() => currentIndex = i),
                itemCount: widget.images.length,
                itemBuilder: (context, i) {
                  final img = widget.images[i];

                  if (widget.aspectRatios[i] == null) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => Container(
                          color: Colors.grey[300],
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ==== BULIR INDIKATOR ====
        Container(
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) {
              final isActive = i == currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 14 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? Colors.red : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
        )
      ],
    );
  }
}