import 'package:flutter/material.dart';
import 'package:kreen_app_flutter/helper/global_var.dart';

class PaymentList extends StatelessWidget {
  final GlobalKey sectionKey;
  final String title;
  final bool isOpen;
  final VoidCallback onTap;
  final List<Widget> children;

  const PaymentList({
    super.key,
    required this.sectionKey,
    required this.title,
    required this.isOpen,
    required this.onTap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: sectionKey,
          onTap: onTap,
          child: Container(
            padding: kGlobalPadding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Icon(isOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),

        if (isOpen) ...[
          const SizedBox(height: 8),
          ...children,
        ],
      ],
    );
  }
}