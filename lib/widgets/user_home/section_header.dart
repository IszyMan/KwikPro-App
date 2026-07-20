import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  /// Optional subtitle
  final String? subtitle;

  /// Optional count shown beside title
  final int? count;

  /// View All callback
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.count,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final scale =
    (MediaQuery.of(context).size.height / 850).clamp(0.9, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: title,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      if (count != null)
                        TextSpan(
                          text: " ($count)",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    children: const [
                      Text(
                        "View All",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 13,
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (subtitle != null) ...[
            const SizedBox(height: 4),

            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14 * scale,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}