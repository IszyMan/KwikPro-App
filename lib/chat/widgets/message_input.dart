import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final ValueChanged<String> onSend;

  const MessageInput({
    super.key,
    required this.onSend,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {

  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [

            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                ),
              ),
            ),

            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {

                if (controller.text.trim().isEmpty) return;

                widget.onSend(controller.text.trim());

                controller.clear();
              },
            )
          ],
        ),
      ),
    );
  }
}