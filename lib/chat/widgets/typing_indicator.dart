import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  final bool typing;

  const TypingIndicator({
    super.key,
    required this.typing,
  });

  @override
  Widget build(BuildContext context) {
    if (!typing) {
      return const SizedBox();
    }

    return const Padding(
      padding: EdgeInsets.only(
        left: 16,
        bottom: 8,
      ),
      child: Text(
        "Typing...",
        style: TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}