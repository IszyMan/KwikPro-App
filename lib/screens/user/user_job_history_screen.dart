import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserJobHistoryScreen extends StatefulWidget {
  const UserJobHistoryScreen({super.key});

  @override
  State<UserJobHistoryScreen> createState() =>
      _UserJobHistoryScreenState();
}

class _UserJobHistoryScreenState
    extends State<UserJobHistoryScreen> {

  final user = FirebaseAuth.instance.currentUser;

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';

    return DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(timestamp.toDate());
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;

      case 'cancelled':
        return Colors.red;

      case 'pending':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  /// ONLY COMPLETED JOBS
  Stream<QuerySnapshot> getJobStream() {
    return FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: user!.uid)
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  void bookAgain(Map<String, dynamic> data) {

    /// YOU CAN NAVIGATE TO BOOKING SCREEN HERE
    /// Example:
    ///
    /// Navigator.push(
    ///   context,
    ///   MaterialPageRoute(
    ///     builder: (_) => RequestServiceScreen(
    ///       service: data['service'],
    ///       technicianId: data['technicianId'],
    ///     ),
    ///   ),
    /// );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Book Again for ${data['service'] ?? 'service'}",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("No user found"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Job History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refresh,

        child: StreamBuilder<QuerySnapshot>(
          stream: getJobStream(),

          builder: (context, snapshot) {

            /// ERROR
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                ),
              );
            }

            /// LOADING
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final jobs = snapshot.data?.docs ?? [];

            /// EMPTY
            if (jobs.isEmpty) {
              return const Center(
                child: Text(
                  "No completed jobs yet",
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 12,
              ),

              itemCount: jobs.length,

              itemBuilder: (context, index) {

                final data = jobs[index].data()
                as Map<String, dynamic>;

                final status =
                    data['status'] ?? 'completed';

                final technicianName =
                    data['technicianName'] ??
                        'Technician';

                final technicianImage =
                    data['technicianImage'] ?? '';

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(16),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          0.05,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(14),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        /// TOP ROW
                        Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            /// TECH IMAGE
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                              Colors.grey.shade200,

                              backgroundImage:
                              technicianImage
                                  .toString()
                                  .isNotEmpty
                                  ? NetworkImage(
                                technicianImage,
                              )
                                  : null,

                              child:
                              technicianImage
                                  .toString()
                                  .isEmpty
                                  ? const Icon(
                                Icons.person,
                                size: 28,
                              )
                                  : null,
                            ),

                            const SizedBox(width: 12),

                            /// DETAILS
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                                children: [

                                  /// SERVICE
                                  Text(
                                    "${data['service'] ?? 'Service'} Job",

                                    maxLines: 1,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,

                                    style:
                                    const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 4,
                                  ),

                                  /// TECH NAME
                                  Text(
                                    technicianName,

                                    maxLines: 1,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,

                                    style:
                                    TextStyle(
                                      fontSize: 14,
                                      color: Colors
                                          .grey
                                          .shade700,
                                      fontWeight:
                                      FontWeight
                                          .w500,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 6,
                                  ),

                                  /// STATUS
                                  Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal:
                                      10,
                                      vertical:
                                      4,
                                    ),

                                    decoration:
                                    BoxDecoration(
                                      color:
                                      getStatusColor(
                                        status,
                                      ).withOpacity(
                                        0.12,
                                      ),

                                      borderRadius:
                                      BorderRadius.circular(
                                        20,
                                      ),
                                    ),

                                    child: Text(
                                      status
                                          .toUpperCase(),

                                      style:
                                      TextStyle(
                                        color:
                                        getStatusColor(
                                          status,
                                        ),
                                        fontSize:
                                        12,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        /// DESCRIPTION
                        if (data['description'] != null &&
                            data['description']
                                .toString()
                                .isNotEmpty)
                          Text(
                            data['description'],

                            maxLines: 2,
                            overflow:
                            TextOverflow.ellipsis,

                            style: TextStyle(
                              color:
                              Colors.grey.shade700,
                            ),
                          ),

                        const SizedBox(height: 10),

                        /// LOCATION
                        Row(
                          children: [

                            Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color:
                              Colors.grey.shade700,
                            ),

                            const SizedBox(width: 4),

                            Expanded(
                              child: Text(
                                data['serviceLocationAddress']
                                    ??
                                    'No location',

                                maxLines: 1,
                                overflow:
                                TextOverflow
                                    .ellipsis,

                                style: TextStyle(
                                  color: Colors
                                      .grey
                                      .shade700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        /// DATE
                        Row(
                          children: [

                            Icon(
                              Icons.access_time,
                              size: 18,
                              color:
                              Colors.grey.shade700,
                            ),

                            const SizedBox(width: 4),

                            Text(
                              formatDate(
                                data['createdAt'],
                              ),

                              style: TextStyle(
                                color: Colors
                                    .grey
                                    .shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        /// BOOK AGAIN BUTTON
                        SizedBox(
                          width: double.infinity,

                          height: 45,

                          child: ElevatedButton.icon(
                            onPressed: () {
                              bookAgain(data);
                            },

                            icon: const Icon(
                              Icons.refresh,
                              size: 20,
                            ),

                            label: const Text(
                              "Book Again",
                            ),

                            style:
                            ElevatedButton.styleFrom(
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}