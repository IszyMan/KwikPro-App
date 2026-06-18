import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ShowcaseFeedWidget extends StatefulWidget {
  const ShowcaseFeedWidget({super.key});

  @override
  State<ShowcaseFeedWidget> createState() => _ShowcaseFeedWidgetState();
}

class _ShowcaseFeedWidgetState extends State<ShowcaseFeedWidget> {
  final Map<String, bool> wouldHireMap = {};

  String formatTime(Timestamp? ts) {
    if (ts == null) return "";
    final diff = DateTime.now().difference(ts.toDate());

    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  void _toggleWouldHire(String postId) {
    setState(() {
      wouldHireMap[postId] = !(wouldHireMap[postId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('showcases')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final postId = doc.id;

            final before = List<String>.from(data['beforeImages'] ?? []);
            final after = List<String>.from(data['afterImages'] ?? []);
            final time = formatTime(data['createdAt']);
            final isWouldHire = wouldHireMap[postId] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// ================= HEADER =================
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage:
                        NetworkImage(data['technicianPhoto'] ?? ''),
                      ),
                      const SizedBox(width: 10),

                      /// NAME + SERVICE TOGETHER
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${data['technicianName'] ?? 'Technician'} • ${data['service'] ?? ''}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 2),

                            /// TIME + LOCATION TOGETHER
                            Text(
                              "$time • 📍 ${data['location'] ?? 'Unknown'}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// ================= CAPTION =================
                  Text(
                    data['caption'] ?? '',
                    style: const TextStyle(height: 1.4),
                  ),

                  const SizedBox(height: 12),

                  /// ================= BEFORE / AFTER CORE UI =================
                  _BeforeAfterScrollView(
                    before: before,
                    after: after,
                  ),

                  const SizedBox(height: 12),

                  const Divider(),
                  const SizedBox(height: 6),

                  /// ================= ACTIONS =================
                  Row(
                    children: [
                      _action(
                        icon: isWouldHire
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: "Would Hire",
                        color: isWouldHire ? Colors.red : null,
                        onTap: () => _toggleWouldHire(postId),
                      ),
                      _action(
                        icon: Icons.handyman_outlined,
                        label: "Book Now",
                        onTap: () {},
                      ),
                      _action(
                        icon: Icons.chat_bubble_outline,
                        label: "Message",
                        onTap: () {},
                      ),
                      _action(
                        icon: Icons.share,
                        label: "Share",
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.black87),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _BeforeAfterScrollView extends StatefulWidget {
  final List<String> before;
  final List<String> after;

  const _BeforeAfterScrollView({
    required this.before,
    required this.after,
  });

  @override
  State<_BeforeAfterScrollView> createState() =>
      _BeforeAfterScrollViewState();
}

class _BeforeAfterScrollViewState extends State<_BeforeAfterScrollView> {
  final PageController _vertical = PageController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: PageView(
        controller: _vertical,
        scrollDirection: Axis.vertical,
        children: [

          /// ================= BEFORE =================
          _MediaSection(
            title: "BEFORE",
            hint: "Swipe up → AFTER",
            images: widget.before,
            color: Colors.orange,
          ),

          /// ================= AFTER =================
          _MediaSection(
            title: "AFTER",
            hint: "Swipe down → BEFORE",
            images: widget.after,
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}


class _MediaSection extends StatelessWidget {
  final String title;
  final String hint;
  final List<String> images;
  final Color color;

  const _MediaSection({
    required this.title,
    required this.hint,
    required this.images,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        /// ================= HORIZONTAL IMAGE SCROLL =================
        PageView.builder(
          controller: PageController(viewportFraction: 0.92),
          itemCount: images.isEmpty ? 1 : images.length,
          itemBuilder: (context, i) {
            if (images.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: Text("No images")),
              );
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(images[i]),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),

        /// ================= LABEL =================
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),

        /// ================= HINT =================
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                hint,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}