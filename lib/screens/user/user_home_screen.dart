import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kwikpro/providers/auth_provider.dart';
import 'package:kwikpro/providers/technician_provider.dart';
import 'package:kwikpro/screens/onboarding/welcome_screen.dart';
import 'package:kwikpro/widgets/technician_card.dart';

class UserHomeScreen extends ConsumerStatefulWidget {
  const UserHomeScreen({super.key});

  @override
  ConsumerState<UserHomeScreen> createState() =>
      _UserHomeScreenState();
}

class _UserHomeScreenState extends ConsumerState<UserHomeScreen>{
  @override
  void initState(){
    super.initState();

    Future.microtask(() {
      ref.read(technicianProvider.notifier).fetchTechnicians();
    });
  }


  @override
  Widget build(BuildContext context) {
    final technicians = ref.watch(technicianProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Technicians'),
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
      body: Padding(
          padding: EdgeInsets.all(20),
          child: technicians.isEmpty
              ? Center(child: Text("No technicians found"))
              : ListView.builder(
                itemCount:  technicians.length,
                itemBuilder: (context, index) {
                  return TechnicianCard(technician: technicians[index],
                  );
                },
                ),
      ),


    );
  }
}