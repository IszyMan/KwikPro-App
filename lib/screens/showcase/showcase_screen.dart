import 'package:flutter/material.dart';
import '../../widgets/showcase_feed_widget.dart';

class ShowcaseScreen extends StatelessWidget {
  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Technician Showcase"),
      ),
      body: Column(
        children: [

          // Future filters
          SizedBox(
            height: 55,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                Chip(label: Text("Trending")),
                Chip(label: Text("Nearby")),
                Chip(label: Text("Verified")),
                Chip(label: Text("Videos")),
                Chip(label: Text("Before & After")),
              ],
            ),
          ),

          Expanded(
            child: ShowcaseFeedWidget(),
          ),
        ],
      ),
    );
  }
}