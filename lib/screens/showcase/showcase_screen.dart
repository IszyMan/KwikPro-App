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
            width: 5,
            height: 55,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                Chip(label: Text("Trending")),
                Chip(label: Text("Nearby")),
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