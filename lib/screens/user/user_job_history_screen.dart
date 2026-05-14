import 'package:flutter/material.dart';


class UserJobHistoryScreen extends StatefulWidget {
  const UserJobHistoryScreen({super.key});

  @override
  State<UserJobHistoryScreen> createState() => _UserJobHistoryScreenState();
}

class _UserJobHistoryScreenState extends State<UserJobHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Text("User job history screen"),);
  }
}
