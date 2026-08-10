// ignore_for_file: unused_field

import 'package:flutter/material.dart';

class FreeVoteFloatingNotif extends StatefulWidget {
  final Map<String, dynamic> bahasa;
  final int freeVote;
  final int freeVoteRemain;
  final String? token;

  const FreeVoteFloatingNotif({
    super.key,
    required this.bahasa,
    required this.freeVote,
    required this.freeVoteRemain,
    this.token,
  });

  @override
  State<FreeVoteFloatingNotif> createState() => _FreeVoteFloatingNotifState();
}

class _FreeVoteFloatingNotifState extends State<FreeVoteFloatingNotif> {
  bool _visible = true;
  bool _closed = false;

  void _handleClose() {
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    // if (widget.freeVote <= 0 || _closed) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      onEnd: () {
        if (!_visible && mounted) {
          setState(() => _closed = true);
        }
      },
      child: IgnorePointer(
        ignoring: !_visible,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerRight,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.bahasa['free_vote_title'] ?? 'Free Vote Available!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 4),
                  if (widget.token != null) ...[
                    Text(
                      (widget.bahasa['free_vote_desc_3'] ?? 'Hi, you have {qty} free {votes}.')
                        .toString()
                        .replaceAll('{qty}', widget.freeVoteRemain.toString())
                        .replaceAll(
                          '{votes}',
                          widget.freeVote > 1
                            ? (widget.bahasa['text_votes'] ?? 'Votes')
                            : (widget.bahasa['text_vote'] ?? 'Vote'),
                        ),
                      textAlign: TextAlign.justify,
                    ),
                  ] else ...[
                    Text(
                      (widget.bahasa['free_vote_desc_2'] ?? 'Please log in to use your {qty} free {votes}.')
                        .toString()
                        .replaceAll('{qty}', widget.freeVote.toString())
                        .replaceAll(
                          '{votes}',
                          widget.freeVote > 1
                            ? (widget.bahasa['text_votes'] ?? 'Votes')
                            : (widget.bahasa['text_vote'] ?? 'Vote'),
                        ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ],
              ),
            ),

            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: _handleClose,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close,
                    size: 24,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}