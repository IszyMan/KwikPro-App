import 'package:flutter_riverpod/legacy.dart';
import 'package:kwikpro/models/technician_model.dart';
import 'package:kwikpro/providers/auth_provider.dart';
import 'package:riverpod/riverpod.dart';



class TechnicianNotifier extends StateNotifier<List<TechnicianModel>> {
  final Ref ref;

  TechnicianNotifier(this.ref) : super([]);

  Future<void> fetchTechnicians() async {
    final firestore = ref.read(firestoreServiceProvider);

    final technicians = await firestore.getTechnicians();
    state = technicians;
  }
}

final technicianProvider = StateNotifierProvider<TechnicianNotifier, List<TechnicianModel>>(
    (ref)  {
      return TechnicianNotifier(ref);
    });