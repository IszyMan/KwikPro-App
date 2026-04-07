import "package:flutter/material.dart";


class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,

  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            SizedBox(width: 4),
            ],
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),),

        ],
      ),

    );
  }
}
