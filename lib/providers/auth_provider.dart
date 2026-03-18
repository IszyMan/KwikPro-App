import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthState {
  final String? role; // 'user' or 'technician'
  final dynamic user; // we’ll replace this with UserModel later

  AuthState({
    this.role,
    this.user,
  });

  AuthState copyWith({
    String? role,
    dynamic user,
  }) {
    return AuthState(
      role: role ?? this.role,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  void setRole(String role) {
    state = state.copyWith(role: role);
  }

  void setUser(dynamic user) {
    state = state.copyWith(user: user);
  }

  void logout() {
    state = AuthState();
  }
}

final authProvider =
StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});



final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});




final firestoreServiceProvider =
Provider<FirestoreService>((ref) {
  return FirestoreService();
});