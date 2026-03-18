import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:kwikpro/providers/auth_provider.dart';

import '../onboarding/welcome_screen.dart';

class TechnicianHomeScreen extends ConsumerStatefulWidget{
  const TechnicianHomeScreen({super.key});

  @override
  ConsumerState<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends ConsumerState<TechnicianHomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('Technician Profile'),
        actions: [IconButton(
          icon: Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () async {
            try {
              await ref.read(authServiceProvider).auth.signOut();
              // clear user from provider
              ref.read(authProvider.notifier).logout();

              //Navigate back to WelcomeScreen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) =>  const WelcomeScreen(),),
                    (route) => false,);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error logging out $e")));
            }

          },
        )
        ],
      ),
      body: Text("This is technician dashboard", ),
    );
  }

}