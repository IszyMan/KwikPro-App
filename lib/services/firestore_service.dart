import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kwikpro/models/technician_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save user
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // Get user
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    } else {
      return null;
    }
  }
  Future<List<TechnicianModel>> getTechnicians() async {
    final snapshot = await _db.collection('technicians').get();

    return snapshot.docs.map((doc) => TechnicianModel.fromMap(doc.data())).toList();
  }

  Future<void> saveTechnician(TechnicianModel technician) async {
    await _db.collection('technicians').doc(technician.uid).set(technician.toMap());
  }
}