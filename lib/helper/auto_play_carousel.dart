import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/widget_webview.dart';

class AutoPlayCarousel extends StatefulWidget {
  final List<String> images;
  final List<dynamic> data;
  final List<double?> aspectRatios;
  final Map<String, dynamic> bahasa;

  const AutoPlayCarousel({
    super.key,
    required this.images,
    required this.data,
    required this.aspectRatios,
    required this.bahasa,
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
    controller = PageController(viewportFraction: 1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoPlay();
    });
  }

  void _startAutoPlay() {
    if (widget.images.length <= 1) return;

    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      if (!controller.hasClients) return;

      final next = (currentIndex + 1) % widget.images.length;

      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );

      currentIndex = next;
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
    final aspect = currentIndex < widget.aspectRatios.length
      ? widget.aspectRatios[currentIndex]
      : null;
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
                physics: const BouncingScrollPhysics(),
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

                  return InkWell(
                    onTap: () {
                      if (widget.data[i]['url_detail'] == null || widget.data[i]['url_detail'] == '') {
                        
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                WidgetWebView(header: widget.bahasa['artikel'], url: widget.data[i]['url_detail']),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Material(
                        borderRadius: BorderRadius.circular(8),
                        clipBehavior: Clip.antiAlias,
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
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        SizedBox(height: 10, child: Container(color: Colors.white,),),

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
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
        )
      ],
    );
  }
}