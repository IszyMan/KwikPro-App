import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:kwikpro/providers/auth_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';



class TechnicianNotifier extends StateNotifier<List<TechnicianModel>> {
  final Ref ref;

  TechnicianNotifier(this.ref) : super([]);

  Future<void> fetchTechnicians() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('technicians')
        .where('isOnline', isEqualTo: true) // ✅ ONLY ONLINE
        .get();

    state = snapshot.docs
        .map((doc) => TechnicianModel.fromMap(doc.data()))
        .toList();
  }
}

final technicianProvider = StateNotifierProvider<TechnicianNotifier, List<TechnicianModel>>(
    (ref)  {
      return TechnicianNotifier(ref);
    });