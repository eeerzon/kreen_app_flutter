import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kreen_app_flutter/helper/constants.dart';

class VoteNotification extends StatelessWidget {
  final String text;
  final Color color;
  final Color bgColor;
  final String themeName;

  const VoteNotification({super.key, required this.text, required this.color, required this.bgColor, required this.themeName});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerLeft,
      children: [
        // 🔹 Container utama
        Container(
          padding: const EdgeInsets.fromLTRB(24, 8, 12, 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color,
              width: 1.5,
            ),
          ),
          child: Text(
            text,
          ),
        ),

        // 🔔 Icon (DI LUAR CONTAINER)
        Positioned(
          left: -12,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.network(
              "$baseUrl/image/icon-vote/$themeName/Notifications.svg",
            ),
          ),
        ),
      ],
    );
  }
}

class VoteNotifStack extends StatefulWidget {
  final List<dynamic> notifList;
  final Color color;
  final Color bgColor;
  final String themeName;
  const VoteNotifStack({
    super.key,
    required this.notifList,
    required this.color,
    required this.bgColor,
    required this.themeName
  });

  @override
  State<VoteNotifStack> createState() => _VoteNotifStackState();
}

class _VoteNotifStackState extends State<VoteNotifStack> {

  final List<String> _visibleNotifs = [];

  @override
  void initState() {
    super.initState();
    _startLoop();
  }

  void _startLoop() async {
    while (mounted) {
      for (var i = 0; i < widget.notifList.length; i++) {
        if (!mounted) return;

        setState(() {
          _visibleNotifs
            ..clear()
            ..add(widget.notifList[i]);
        });

        await Future.delayed(const Duration(seconds: 3));

        if (!mounted) return;

        setState(() {
          _visibleNotifs.clear();
        });

        await Future.delayed(const Duration(milliseconds: 200)); // jeda halus
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _visibleNotifs
          .map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: VoteNotification(
                text: text,
                color: widget.color,
                bgColor: widget.bgColor,
                themeName: widget.themeName
              ),
            ),
          )
          .toList(),
    );
  }
}