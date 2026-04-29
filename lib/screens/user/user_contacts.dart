import 'package:flutter/material.dart';



class UserContacts extends StatefulWidget {
  const UserContacts({super.key});

  @override
  State<UserContacts> createState() => _UserContactsState();
}

class _UserContactsState extends State<UserContacts> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Contacts"),),
    );
  }
}
