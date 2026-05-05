
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class RunningText extends StatefulWidget {
  final String text;
  final Color textColor;

  const RunningText({super.key, required this.text, required this.textColor});

  @override
  State<RunningText> createState() => RunningTextState();
}

class RunningTextState extends State<RunningText> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _offset = 0;
  double _containerWidth = 0;
  double _textWidth = 0;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker((_) {
      if (_containerWidth == 0 || _textWidth == 0) return;

      setState(() {
        _offset -= 1.5; // kecepatan scroll

        // jika text sudah keluar semua ke kiri, reset dari kanan
        if (_offset <= -_textWidth) {
          _offset = _containerWidth;
        }
      });
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _containerWidth = constraints.maxWidth;

        // init offset dari kanan saat pertama
        if (_offset == 0 && _textWidth == 0) {
          _offset = _containerWidth;
        }

        return SizedBox(
          height: 28,
          child: ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: _offset,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: MeasureTextWidth(
                      text: widget.text,
                      style: TextStyle(color: widget.textColor),
                      onMeasured: (w) {
                        if (_textWidth != w) {
                          setState(() {
                            _textWidth = w;
                            _offset = _containerWidth; // mulai dari kanan
                          });
                        }
                      },
                      child: Text(
                        widget.text,
                        style: TextStyle(color: widget.textColor),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}

class MeasureTextWidth extends StatefulWidget {
  final Widget child;
  final String text;
  final TextStyle style;
  final ValueChanged<double> onMeasured;

  const MeasureTextWidth({
    super.key,
    required this.child,
    required this.text,
    required this.style,
    required this.onMeasured,
  });

  @override
  State<MeasureTextWidth> createState() => _MeasureTextWidthState();
}

class _MeasureTextWidthState extends State<MeasureTextWidth> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: widget.style),
        textDirection: TextDirection.ltr,
      )..layout();
      widget.onMeasured(painter.width);
    });
    return widget.child;
  }
}