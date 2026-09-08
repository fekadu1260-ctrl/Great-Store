import 'package:flutter/material.dart';

class FloralDivider extends StatelessWidget {
  final IconData icon;
  final Color color;

  const FloralDivider({
    super.key,
    this.icon = Icons.local_florist,
    this.color = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            thickness: 1,
            color: color.withValues(alpha: 0.3),
            indent: 16,
            endIndent: 12,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color.withValues(alpha: 0.6)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Icon(icon, size: 18, color: color),
            ),
            Icon(icon, size: 12, color: color.withValues(alpha: 0.6)),
          ],
        ),
        Expanded(
          child: Divider(
            thickness: 1,
            color: color.withValues(alpha: 0.3),
            indent: 12,
            endIndent: 16,
          ),
        ),
      ],
    );
  }
}
