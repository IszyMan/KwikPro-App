import 'package:flutter/material.dart';
import 'package:kwikpro/screens/technician/technician_accepted_jobs_screen.dart';
import 'incoming_requests_screen.dart';
import 'completed_jobs_screen.dart';

class TechnicianDashboard extends StatefulWidget {
  const TechnicianDashboard({super.key});

  @override
  State<TechnicianDashboard> createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

  }

  void goToAcceptedJobs() {
    setState(() {
      _tabController.animateTo(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Technician Dashboard"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Incoming Requests"),
            Tab(text: "Accepted Jobs"),
            Tab(text: "Completed Jobs"),
          ],
        ),
      ),
      body: TabBarView(
        physics: AlwaysScrollableScrollPhysics(),
        controller: _tabController,
        children: [
          IncomingRequestsScreen(onJobAccepted: goToAcceptedJobs),
          TechnicianActiveJobsScreen(),
          CompletedJobsScreen(),
        ],
      ),
    );
  }
}