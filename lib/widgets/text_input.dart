import 'package:flutter/material.dart';

class TextInput extends StatelessWidget {
  final String hint;
  final TextEditingController controller;

  const TextInput({super.key, required this.hint, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}