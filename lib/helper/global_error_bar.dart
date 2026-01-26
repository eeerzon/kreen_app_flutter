import 'package:flutter/material.dart';

class GlobalErrorBar extends StatelessWidget {
  final bool visible;
  final String message;
  final VoidCallback onRetry;

  const GlobalErrorBar({
    super.key,
    required this.visible,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: InkWell(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.refresh, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}