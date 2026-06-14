import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/chat/chat_screens.dart';

class ShowcaseFeedWidget extends StatefulWidget {
  const ShowcaseFeedWidget({super.key});

  @override
  State<ShowcaseFeedWidget> createState() => _ShowcaseFeedWidgetState();
}

class _ShowcaseFeedWidgetState extends State<ShowcaseFeedWidget> {
  final Map<String, bool> wouldHireMap = {};

  bool get isUser => true;

  String formatTime(Timestamp? ts) {
    if (ts == null) return "";

    final diff = DateTime.now().difference(ts.toDate());

    if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";

    return "${ts.toDate().day}/${ts.toDate().month}";
  }

  void _openChat({
    required String requestId,
    required String otherUserId,
    required String name,
    String? image,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          requestId: requestId,
          otherUserId: otherUserId,
          otherUserName: name,
          otherUserImage: image,
        ),
      ),
    );
  }

  void _toggleWouldHire(String postId) {
    setState(() {
      wouldHireMap[postId] = !(wouldHireMap[postId] ?? false);
    });

    // TODO:
    // Firestore increment:
    // if true -> increment wouldHire count
    // if false -> decrement
  }

  Widget _media(String url, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              url,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color ?? Colors.black87),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color ?? Colors.black87),
            ),
          ],
        ),
      ),
    );
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

            final isWouldHire = wouldHireMap[postId] ?? false;
            final time = formatTime(data['createdAt']);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ================= HEADER =================
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage:
                        NetworkImage(data['technicianPhoto'] ?? ''),
                      ),
                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  data['technicianName'] ?? 'Technician',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    data['service'] ?? 'Service',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$time · ${data['location'] ?? ''}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      if (isUser)
                        TextButton(
                          onPressed: () {},
                          child: const Text("Follow"),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ================= DESCRIPTION =================
                  Text(
                    data['caption'] ?? '',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),

                  const SizedBox(height: 12),

                  // ================= BEFORE / AFTER =================
                  SizedBox(
                    height: 240,
                    child: PageView.builder(
                      controller:
                      PageController(viewportFraction: 0.92),
                      itemCount: after.length,
                      itemBuilder: (context, i) {
                        return Stack(
                          children: [
                            _media(after[i], "After"),

                            if (i < before.length)
                              Positioned(
                                left: 10,
                                bottom: 10,
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      before[i],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 6),

                  // ================= ACTION BAR (EQUAL SPACING) =================
                  Row(
                    children: [

                      // WOULD HIRE (ONLY REACTION)
                      _actionItem(
                        icon: isWouldHire
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: isWouldHire ? "Would Hire" : "Hire",
                        color: isWouldHire ? Colors.red : null,
                        onTap: () => _toggleWouldHire(postId),
                      ),

                      // BOOK NOW
                      _actionItem(
                        icon: Icons.handyman_outlined,
                        label: "Book",
                        onTap: () {},
                      ),

                      // MESSAGE
                      _actionItem(
                        icon: Icons.chat_bubble_outline,
                        label: "Message",
                        onTap: () {
                          _openChat(
                            requestId: postId,
                            otherUserId: data['technicianId'],
                            name: data['technicianName'],
                            image: data['technicianPhoto'],
                          );
                        },
                      ),

                      // SHARE
                      _actionItem(
                        icon: Icons.share_outlined,
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
}