import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/technician_model.dart';

class ViewTechnicianProfileScreen extends StatefulWidget {
  final TechnicianModel technician;
  final double? userLat;
  final double? userLng;
  final String serviceLocationAddress;
  final String issueDescription;
  final String imageUrl;
  final List<String> selectedSkills;

  const ViewTechnicianProfileScreen({
    super.key,
    required this.technician,
    required this.userLat,
    required this.userLng,
    required this.serviceLocationAddress,
    required this.issueDescription,
    required this.imageUrl,
    required this.selectedSkills,
  });

  @override
  State<ViewTechnicianProfileScreen> createState() =>
      _ViewTechnicianProfileScreenState();
}

class _ViewTechnicianProfileScreenState
    extends State<ViewTechnicianProfileScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// FETCH REVIEW STATS
  Future<Map<String, dynamic>> _getStats() async {

    final snap = await FirebaseFirestore.instance
        .collection('reviews')
        .where(
      'technicianId',
      isEqualTo: widget.technician.uid,
    )
        .get();

    final docs = snap.docs;

    final count = docs.length;

    if (count == 0) {
      return {
        "completedJobs": 0,
        "avgRating": 0.0,
        "avgPrice": 0.0,
        "avgService": 0.0,
      };
    }

    double totalRating = 0;
    double totalPrice = 0;
    double totalService = 0;

    for (final doc in docs) {

      final data = doc.data();

      totalRating +=
          (data['rating'] ?? 0).toDouble();

      totalPrice +=
          (data['priceRating'] ?? 0).toDouble();

      totalService +=
          (data['serviceRating'] ?? 0).toDouble();
    }

    return {
      "completedJobs": count,
      "avgRating": totalRating / count,
      "avgPrice": totalPrice / count,
      "avgService": totalService / count,
    };
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.technician.name),
      ),

      body: FutureBuilder<Map<String, dynamic>>(

        future: _getStats(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text("Failed to load profile"),
            );
          }

          final data = snapshot.data!;

          final completedJobs =
          data['completedJobs'];

          final avgRating =
          data['avgRating'];

          //final avgPrice =
          //data['avgPrice'];

          //final avgService =
          //data['avgService'];

          return Column(
            children: [

              /// BODY
              Expanded(
                child: SingleChildScrollView(

                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      /// HEADER
                      Row(
                        children: [

                          CircleAvatar(
                            radius: 42,

                            backgroundImage:
                            (widget.technician.profilePic
                                ?.isNotEmpty ??
                                false)
                                ? NetworkImage(
                                widget.technician.profilePic!)
                                : null,

                            child:
                            (widget.technician.profilePic
                                ?.isEmpty ??
                                true)
                                ? const Icon(
                              Icons.person,
                              size: 40,
                            )
                                : null,
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,

                              children: [

                                Text(
                                  widget.technician.name,

                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  widget.technician.service,

                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Row(
                                  children: [

                                    Icon(
                                      Icons.verified,
                                      color:
                                      widget.technician
                                          .isVerified
                                          ? Colors.green
                                          : Colors.grey,
                                      size: 18,
                                    ),

                                    const SizedBox(width: 5),

                                    Text(
                                      widget.technician
                                          .isVerified
                                          ? "Verified Technician"
                                          : "Not Verified",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 24),

                      /// STATS
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,

                        children: [

                          _statChip(
                            "Jobs Completed",
                            "$completedJobs",
                            Colors.green,
                          ),

                          _statChip(
                            "Rating",
                            avgRating
                                .toStringAsFixed(1),
                            Colors.blue,
                          ),

                         // _statChip(
                          //  "Price",
                          //  avgPrice
                         //       .toStringAsFixed(1),
                         //   Colors.orange,
                         // ),

                         // _statChip(
                         //   "Service",
                         //   avgService
                          //      .toStringAsFixed(1),
                          //  Colors.purple,
                         // ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      /// TAB BAR
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius:
                          BorderRadius.circular(12),
                        ),

                        child: TabBar(

                          controller: _tabController,

                          indicator: UnderlineTabIndicator(
                            borderSide: BorderSide(
                              width: 5,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),

                          labelColor: Colors.blue,

                          unselectedLabelColor:
                          Colors.black87,

                          tabs: const [

                            Tab(text: "Technician Bio"),

                            //Tab(text: "Work Tools"),

                            Tab(text: "Previous Work images"),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        height: 550,

                        child: TabBarView(

                          controller: _tabController,

                          children: [

                            /// BIO TAB
                            _buildBio(),

                            /// TOOLS TAB
                           // _buildGallery(
                            //  widget.technician
                            //      .workToolsImages ??
                           //       [],
                          //  ),

                            /// WORK TAB
                            _buildGallery(
                              widget.technician
                                  .previousWorkImages ??
                                  [],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// REQUEST BUTTON
              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color:
                      Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    )
                  ],
                ),

                child: SizedBox(
                  width: double.infinity,

                  height: 52,

                  child: ElevatedButton(
                    onPressed: () {

                      Navigator.pop(context);

                    },

                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),

                    child: const Text(
                      "Request Service",
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  /// BIO TAB
  Widget _buildBio() {

    return SingleChildScrollView(

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          /// AREA
          const Text(
            "Area of Operation",

            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            widget.technician.address,
          ),

          const SizedBox(height: 20),

          /// EXPERIENCE
          const Text(
            "Years of Experience",

            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "${widget.technician.yearsOfExperience} years",
          ),

          const SizedBox(height: 24),

          /// SKILLS
          const Text(
            "Skills",

            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,

            children:
            (widget.technician.skills ?? [])
                .map(
                  (skill) => Chip(
                label: Text(skill),
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }

  /// IMAGE GALLERY
  Widget _buildGallery(List<String> images) {

    if (images.isEmpty) {
      return const Center(
        child: Text(
          "No images uploaded yet",
        ),
      );
    }

    return GridView.builder(

      itemCount: images.length,

      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(

        crossAxisCount: 2,

        crossAxisSpacing: 10,

        mainAxisSpacing: 10,
      ),

      itemBuilder: (context, index) {

        return GestureDetector(

          onTap: () {

            showDialog(

              context: context,

              builder: (_) {

                return Dialog(

                  backgroundColor: Colors.black,

                  insetPadding:
                  const EdgeInsets.all(10),

                  child: InteractiveViewer(
                    child: Image.network(
                      images[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            );
          },

          child: ClipRRect(

            borderRadius:
            BorderRadius.circular(14),

            child: Image.network(
              images[index],
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  /// STATS CHIP
  Widget _statChip(
      String label,
      String value,
      Color color,
      ) {

    return Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      decoration: BoxDecoration(

        color: color.withOpacity(0.12),

        borderRadius:
        BorderRadius.circular(20),

        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [

          Text(
            value,

            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(width: 5),

          Text(
            label,

            style: TextStyle(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}