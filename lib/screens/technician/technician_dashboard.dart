import 'package:flutter/material.dart';
import 'package:kwikpro/screens/technician/technician_jobs_screen.dart';
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
            Tab(text: "Jobs Requests"),
            Tab(text: "Completed Jobs"),
          ],
        ),
      ),
      body: TabBarView(
        physics: AlwaysScrollableScrollPhysics(),
        controller: _tabController,
        children: [
          TechnicianJobsScreen(),
          CompletedJobsScreen(),
        ],
      ),
    );
  }
}