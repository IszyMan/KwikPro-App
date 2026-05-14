import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TechnicianDetailsScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const TechnicianDetailsScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<TechnicianDetailsScreen> createState() =>
      _TechnicianDetailsScreenState();
}

class _TechnicianDetailsScreenState
    extends State<TechnicianDetailsScreen>
    with SingleTickerProviderStateMixin {

  late bool isVerified;
  late bool isSuspended;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    isVerified =
        widget.data['isVerified'] ?? false;

    isSuspended =
        widget.data['isSuspended'] ?? false;

    _tabController = TabController(
      length: 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final name =
        widget.data['name'] ?? 'No Name';

    final experience =
        widget.data['yearsOfExperience'] ?? 0;

    final location =
        widget.data['location'] ?? 'No Location';

    final profilePic =
        widget.data['profilePic'] ?? '';

    final ninImage =
        widget.data['ninImage'] ?? '';

    final service =
        widget.data['service'] ?? 'No Service';

    /// NEW MULTIPLE IMAGES
    final List<String> workToolsImages =
    List<String>.from(
        widget.data['workToolsImages'] ?? []);

    final List<String> previousWorkImages =
    List<String>.from(
        widget.data['previousWorkImages'] ?? []);

    return Scaffold(

      appBar: AppBar(
        title: Text("$name Details"),
        centerTitle: true,
      ),

      body: Column(
        children: [

          /// BODY
          Expanded(
            child: SingleChildScrollView(

              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  /// HEADER CARD
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(20),

                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .primaryColor,

                          Theme.of(context)
                              .primaryColor
                              .withOpacity(0.7),
                        ],
                      ),
                    ),

                    child: Column(
                      children: [

                        CircleAvatar(
                          radius: 50,

                          backgroundColor:
                          Colors.white,

                          backgroundImage:
                          profilePic.isNotEmpty
                              ? NetworkImage(profilePic)
                              : null,

                          child: profilePic.isEmpty
                              ? Text(
                            name[0]
                                .toUpperCase(),

                            style:
                            const TextStyle(
                              fontSize: 38,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          )
                              : null,
                        ),

                        const SizedBox(height: 14),

                        Text(
                          name,

                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight:
                            FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "$service • $experience years experience",

                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          location,

                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,

                          alignment:
                          WrapAlignment.center,

                          children: [

                            _statusChip(
                              isVerified
                                  ? "Verified"
                                  : "Not Verified",

                              isVerified
                                  ? Colors.green
                                  : Colors.orange,

                              isVerified
                                  ? Icons.verified
                                  : Icons.warning,
                            ),

                            _statusChip(
                              isSuspended
                                  ? "Suspended"
                                  : "Active",

                              isSuspended
                                  ? Colors.red
                                  : Colors.green,

                              isSuspended
                                  ? Icons.block
                                  : Icons.check_circle,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// TAB BAR
                  Container(

                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,

                      borderRadius:
                      BorderRadius.circular(14),
                    ),

                    child: TabBar(

                      controller: _tabController,

                      indicator: BoxDecoration(
                        color:
                        Theme.of(context).primaryColor,

                        borderRadius:
                        BorderRadius.circular(14),
                      ),

                      labelColor: Colors.white,

                      unselectedLabelColor:
                      Colors.black87,

                      tabs: const [

                        Tab(text: "Profile"),

                        Tab(text: "NIN"),

                        Tab(text: "Tools"),

                        Tab(text: "Previous Work"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 650,

                    child: TabBarView(

                      controller: _tabController,

                      children: [

                        /// PROFILE TAB
                        _buildProfileTab(
                          profilePic,
                          service,
                          experience,
                          location,
                        ),

                        /// NIN TAB
                        _buildSingleImage(
                          ninImage,
                          "No NIN uploaded",
                        ),

                        /// TOOLS TAB
                        _buildGallery(
                          workToolsImages,
                          "No tools images uploaded",
                        ),

                        /// PREVIOUS WORK TAB
                        _buildGallery(
                          previousWorkImages,
                          "No previous work images uploaded",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// ACTION BUTTONS
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

            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [

                /// VERIFY BUTTON
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.42,

                  child: ElevatedButton.icon(

                    onPressed: () async {

                      setState(() {
                        isVerified = !isVerified;
                      });

                      await FirebaseFirestore.instance
                          .collection('technicians')
                          .doc(widget.docId)
                          .update({
                        'isVerified':
                        isVerified,
                      });
                    },

                    icon: Icon(
                      isVerified
                          ? Icons.close
                          : Icons.verified,
                    ),

                    label: Text(
                      isVerified
                          ? "Unverify"
                          : "Verify",
                    ),

                    style:
                    ElevatedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// SUSPEND BUTTON
                Expanded(
                  child: ElevatedButton.icon(

                    onPressed: () async {

                      setState(() {
                        isSuspended =
                        !isSuspended;
                      });

                      await FirebaseFirestore.instance
                          .collection('technicians')
                          .doc(widget.docId)
                          .update({
                        'isSuspended':
                        isSuspended,
                      });
                    },

                    icon: Icon(
                      isSuspended
                          ? Icons.check_circle
                          : Icons.block,
                    ),

                    label: Text(
                      isSuspended
                          ? "Unsuspend"
                          : "Suspend",
                    ),

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.red,

                      padding:
                      const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// PROFILE TAB
  Widget _buildProfileTab(
      String profilePic,
      String service,
      int experience,
      String location,
      ) {

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        const Text(
          "Technician Information",

          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 20),

        _infoTile(
          Icons.work,
          "Service",
          service,
        ),

        _infoTile(
          Icons.location_on,
          "Location",
          location,
        ),

        _infoTile(
          Icons.badge,
          "Experience",
          "$experience years",
        ),

        const SizedBox(height: 24),

        const Text(
          "Profile Picture",

          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ClipRRect(
          borderRadius:
          BorderRadius.circular(16),

          child: profilePic.isNotEmpty
              ? Image.network(
            profilePic,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
          )
              : Container(
            height: 250,

            width: double.infinity,

            color: Colors.grey.shade200,

            child: const Center(
              child: Text("No profile image"),
            ),
          ),
        )
      ],
    );
  }

  /// MULTIPLE IMAGES
  Widget _buildGallery(
      List<String> images,
      String emptyText,
      ) {

    if (images.isEmpty) {
      return Center(
        child: Text(emptyText),
      );
    }

    return GridView.builder(

      itemCount: images.length,

      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
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
            BorderRadius.circular(16),

            child: Stack(
              children: [

                Positioned.fill(
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,

                  child: Container(
                    padding:
                    const EdgeInsets.all(8),

                    color:
                    Colors.black.withOpacity(0.45),

                    child: Text(
                      "Tap to view",

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  /// SINGLE IMAGE
  Widget _buildSingleImage(
      String image,
      String emptyText,
      ) {

    if (image.isEmpty) {
      return Center(
        child: Text(emptyText),
      );
    }

    return Align(

      alignment: Alignment.topCenter,

      child: GestureDetector(

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
                    image,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          );
        },

        child: Container(

          width: 220,
          height: 280,

          margin: const EdgeInsets.only(top: 8),

          decoration: BoxDecoration(

            borderRadius:
            BorderRadius.circular(16),

            image: DecorationImage(
              image: NetworkImage(image),
              fit: BoxFit.cover,
            ),
          ),

          child: Align(

            alignment: Alignment.bottomCenter,

            child: Container(

              width: double.infinity,

              padding: const EdgeInsets.all(10),

              decoration: BoxDecoration(

                color: Colors.black.withOpacity(0.45),

                borderRadius:
                const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),

              child: const Text(
                "Tap to view",

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// INFO TILE
  Widget _infoTile(
      IconData icon,
      String title,
      String value,
      ) {

    return Container(

      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.grey.shade100,

        borderRadius:
        BorderRadius.circular(14),
      ),

      child: Row(
        children: [

          Icon(icon),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  title,

                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// STATUS CHIP
  Widget _statusChip(
      String text,
      Color color,
      IconData icon,
      ) {

    return Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(0.15),

        borderRadius:
        BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [

          Icon(
            icon,
            color: color,
            size: 18,
          ),

          const SizedBox(width: 6),

          Text(
            text,

            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}