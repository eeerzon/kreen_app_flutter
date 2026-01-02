// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class InfiniteSponsorMarquee extends StatefulWidget {
  final List sponsors;
  final double height;
  final double speed; // pixel per second
  final bool showFade;

  const InfiniteSponsorMarquee({
    super.key,
    required this.sponsors,
    this.height = 48,
    this.speed = 30,
    this.showFade = true,
  });

  @override
  State<InfiniteSponsorMarquee> createState() =>
      _InfiniteSponsorMarqueeState();
}

class _InfiniteSponsorMarqueeState extends State<InfiniteSponsorMarquee>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _offset = 0;
  double _singleSetWidth = 0;
  bool _paused = false;
  Timer? _resumeTimer;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker((elapsed) {
      if (_paused || _singleSetWidth == 0) return;

      final delta = widget.speed / 60; // assuming ~60fps
      setState(() {
        _offset -= delta;
        if (_offset <= -_singleSetWidth) {
          _offset += _singleSetWidth; // wrap WITHOUT jump
        }
      });
    })..start();
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void _pause() {
    _paused = true;
    _resumeTimer?.cancel();
  }

  void _resumeWithDelay() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: 800), () {
      _paused = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    Widget content = ClipRect(
      child: GestureDetector(
        onPanDown: (_) => _pause(),
        onPanEnd: (_) => _resumeWithDelay(),
        onTapDown: (_) => _pause(),
        onTapUp: (_) => _resumeWithDelay(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return OverflowBox(
              minWidth: 0,
              maxWidth: double.infinity, // IZINKAN OVERFLOW
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(_offset, 0),
                child: Row(
                  children: [
                    _SponsorRow(
                      sponsors: widget.sponsors,
                      height: widget.height,
                      onMeasured: (w) => _singleSetWidth = w,
                    ),
                    _SponsorRow(
                      sponsors: widget.sponsors,
                      height: widget.height,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    if (!widget.showFade) return SizedBox(height: widget.height, child: content);

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          children: [
            content,
            if (widget.showFade) _FadeEdge(left: true),
            if (widget.showFade) _FadeEdge(left: false),
          ],
        ),
      ),
    );
  }
}

class _SponsorRow extends StatelessWidget {
  final List sponsors;
  final double height;
  final ValueChanged<double>? onMeasured;

  const _SponsorRow({
    required this.sponsors,
    required this.height,
    this.onMeasured,
  });

  @override
  Widget build(BuildContext context) {
    return MeasureSize(
      onChange: (size) => onMeasured?.call(size.width),
      child: Row(
        children: sponsors.map<Widget>((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 24),
            child: SizedBox(
              height: height,
              child: Image.network(
                item['src'],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FadeEdge extends StatelessWidget {
  final bool left;
  const _FadeEdge({required this.left});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: left ? Alignment.centerLeft : Alignment.centerRight,
              end: left ? Alignment.centerRight : Alignment.centerLeft,
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.0),
              ],
              stops: const [0.0, 0.15],
            ),
          ),
        ),
      ),
    );
  }
}

/// Utility to measure widget size
class MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;
  const MeasureSize({super.key, required this.child, required this.onChange});

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  Size _oldSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contextSize = context.size;
      if (contextSize != null && _oldSize != contextSize) {
        _oldSize = contextSize;
        widget.onChange(contextSize);
      }
    });
    return widget.child;
  }
}
