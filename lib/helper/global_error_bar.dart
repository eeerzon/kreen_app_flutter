import 'package:flutter/material.dart';

class GlobalErrorBar extends StatefulWidget {
  final bool visible;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onDismiss;

  const GlobalErrorBar({
    super.key,
    required this.visible,
    required this.message,
    required this.onRetry,
    this.onDismiss,
  });

  @override
  State<GlobalErrorBar> createState() => _GlobalErrorBarState();
}

class _GlobalErrorBarState extends State<GlobalErrorBar> {
  bool _localVisible = true;

  @override
  void didUpdateWidget(GlobalErrorBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible) {
      _localVisible = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || !_localVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: Dismissible(
        key: const ValueKey("global_error_bar"),
        direction: DismissDirection.up,
        onDismissed: (_) {
          setState(() => _localVisible = false);
          widget.onDismiss?.call();
        },
        child: InkWell(
          onTap: widget.onRetry,
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
                    widget.message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.refresh, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}