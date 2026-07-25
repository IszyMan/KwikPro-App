import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ShowcaseFeedWidget extends StatefulWidget {
  const ShowcaseFeedWidget({super.key});

  @override
  State<ShowcaseFeedWidget> createState() => _ShowcaseFeedWidgetState();
}

class _ShowcaseFeedWidgetState extends State<ShowcaseFeedWidget> {
  final Map<String, bool> wouldHireMap = {};
  final ScrollController _feedController = ScrollController();
  final List<GlobalKey> _cardKeys = [];

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

  Future<void> _scrollToNextPost(int index) async {
    if (index + 1 >= _cardKeys.length) return;

    final context = _cardKeys[index + 1].currentContext;

    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0,
      );
    }
  }

  Future<void> _scrollToPreviousPost(int index) async {
    if (index <= 0) return;

    final context = _cardKeys[index - 1].currentContext;

    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0,
      );
    }
  }

  @override
  void dispose() {
    _feedController.dispose();
    super.dispose();
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

        while (_cardKeys.length < docs.length) {
          _cardKeys.add(GlobalKey());
        }

        return ListView.builder(
          controller: _feedController,
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
              key: _cardKeys[index],
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
                    onNextPost: () => _scrollToNextPost(index),
                    onPreviousPost: () => _scrollToPreviousPost(index),
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

  final VoidCallback onNextPost;
  final VoidCallback onPreviousPost;

  const _BeforeAfterScrollView({
    super.key,
    required this.before,
    required this.after,
    required this.onNextPost,
    required this.onPreviousPost,
  });

  @override
  State<_BeforeAfterScrollView> createState() =>
      _BeforeAfterScrollViewState();
}

class _BeforeAfterScrollViewState
    extends State<_BeforeAfterScrollView> {

  bool _showAfter = false;

  double _dragDistance = 0;

  static const double _threshold = 70;

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.delta.dy;
  }

  void _onVerticalDragEnd(DragEndDetails details) async {

    //
    // Swipe Up
    //
    if (_dragDistance < -_threshold) {

      if (!_showAfter) {
        setState(() {
          _showAfter = true;
        });
      } else {

        widget.onNextPost();
      }
    }

    //
    // Swipe Down
    //
    else if (_dragDistance > _threshold) {

      if (_showAfter) {
        setState(() {
          _showAfter = false;
        });
      } else {

        widget.onPreviousPost();
      }
    }

    _dragDistance = 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      onVerticalDragUpdate: _onVerticalDragUpdate,

      onVerticalDragEnd: _onVerticalDragEnd,

      child: SizedBox(
        height: 280,
        child: _MediaSection(
          images: _showAfter
              ? widget.after
              : widget.before,

          title: _showAfter ? "AFTER" : "BEFORE",

          hint: _showAfter
              ? "Swipe ↓ for BEFORE"
              : "Swipe ↑ for AFTER",

          color: _showAfter
              ? Colors.green
              : Colors.orange,
        ),
      ),
    );
  }
}

class _MediaSection extends StatefulWidget {
  final String title;
  final String hint;
  final List<String> images;
  final Color color;

  const _MediaSection({
    super.key,
    required this.title,
    required this.hint,
    required this.images,
    required this.color,
  });

  @override
  State<_MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<_MediaSection> {
  late final PageController _images;

  int _currentImage = 0;

  @override
  void initState() {
    super.initState();

    _images = PageController(
      viewportFraction: 0.92,
    );
  }

  @override
  void dispose() {
    _images.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        /// ================= HORIZONTAL IMAGE SCROLL =================
        PageView.builder(
          controller: _images,
          onPageChanged: (index) {
            setState(() {
              _currentImage = index;
            });
          },
          itemCount: widget.images.isEmpty ? 1 : widget.images.length,
          itemBuilder: (context, i) {
            if (widget.images.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text("No images"),
                ),
              );
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(widget.images[i]),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),

        /// ================= IMAGE COUNTER =================
        Positioned(
          top: 10,
          right: 22,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${widget.images.isEmpty ? 0 : _currentImage + 1}/${widget.images.isEmpty ? 0 : widget.images.length}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),


        /// ================= BEFORE / AFTER =================
        Positioned(
          top: 10,
          left: 22,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.hint,
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