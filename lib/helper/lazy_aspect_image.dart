import 'package:flutter/material.dart';

class LazyAspectImage extends StatefulWidget {
  final String url;
  const LazyAspectImage({super.key, required this.url});

  @override
  State<LazyAspectImage> createState() => _LazyAspectImageState();
}

class _LazyAspectImageState extends State<LazyAspectImage> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        widget.url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loading) {
          if (loading != null) {
            return Container(
              color: Colors.grey[200],
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            );
          }
          return child;
        },
        errorBuilder: (context, child, loading) {
          return Container(
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image),
          );
        },
      ),
    );
  }
}
