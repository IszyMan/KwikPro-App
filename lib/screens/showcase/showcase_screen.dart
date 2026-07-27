import 'package:flutter/material.dart';
import '../../widgets/showcase_feed_widget.dart';

class ShowcaseScreen extends StatelessWidget {
  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Technician Showcases"),

      ),
      body: Column(
        children: [

          // Future filters
          SizedBox(
            height: 55,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: const [
                Chip(label: Text("Trending")),
                SizedBox(width: 8),
                Chip(label: Text("Nearby")),
                SizedBox(width: 8),
                Chip(label: Text("Videos")),
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