import 'package:flutter/material.dart';

class ShowcaseGalleryScreen extends StatelessWidget {
  final Map<String, dynamic> showcaseData;

  const ShowcaseGalleryScreen({
    super.key,
    required this.showcaseData,
  });

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(
      showcaseData['images'] ?? [],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Showcase Gallery"),
      ),
      body: images.isEmpty
          ? const Center(child: Text("No images in this showcase"))
          : GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              images[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}