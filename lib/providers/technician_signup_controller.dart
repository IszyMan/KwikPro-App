import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/technician_model.dart';
import '../models/technician_signup_state.dart';
import '../screens/technician/technician_main_screen.dart';
import '../services/location_service.dart';
import 'auth_provider.dart';

final technicianSignupController =
StateNotifierProvider<TechnicianSignupController, TechnicianSignupState>(
        (ref) => TechnicianSignupController());

class TechnicianSignupController
    extends StateNotifier<TechnicianSignupState> {
  TechnicianSignupController() : super(TechnicianSignupState()) {
    loadDraft();
  }

  void nextStep() {
    state = state.copyWith(step: state.step + 1);
    saveDraft();
  }

  void back() {
    state = state.copyWith(step: state.step - 1);
    saveDraft();
  }

  void setBasicInfo(String name, String? service) {
    state = state.copyWith(name: name, service: service);
    saveDraft();
  }

  void setService(String? service) {
    state = state.copyWith(service: service);
    saveDraft();
  }

  void setWorkDetails(int years, String address) {
    state = state.copyWith(years: years, address: address);
    saveDraft();
  }

  void setImage({required String type, required String path}) {
    if (type == "tools") {
      state = state.copyWith(toolsImage: path);
    } else if (type == "profile") {
      state = state.copyWith(profileImage: path.isEmpty ? null : path,);
    } else if (type == "work") {
      state = state.copyWith(workImage: path);
    } else if (type == "nin") {
      state = state.copyWith(ninImage: path);
    }
    saveDraft();
  }

  ///  AUTO SAVE
  Future<void> saveDraft() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString("signup_draft", jsonEncode({
      "step": state.step,
      "name": state.name,
      "service": state.service,
      "years": state.years,
      "address": state.address,
      "profileImage": state.profileImage,
      "toolsImage": state.toolsImage,
      "workImage": state.workImage,
      "ninImage": state.ninImage,
    }));
  }

  /// LOAD SAVED DATA
  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("signup_draft");

    if (data != null) {
      final decoded = jsonDecode(data);

      state = state.copyWith(
        step: decoded["step"],
        name: decoded["name"],
        service: decoded["service"],
        years: decoded["years"],
        address: decoded["address"],
        profileImage: decoded["profileImage"],
        toolsImage: decoded["toolsImage"],
        workImage: decoded["workImage"],
        ninImage: decoded["ninImage"],
      );
    }
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("signup_draft");
  }

  Future<void> submit(BuildContext context, WidgetRef ref) async {
    state = state.copyWith(isLoading: true);

    try {
      final auth = ref.read(authProvider);
      final firestore = ref.read(firestoreServiceProvider);

      final location = await LocationService().getCurrentLocation();

      final tech = TechnicianModel(
        uid: auth.user!.uid,
        name: state.name,
        service: state.service!,
        yearsOfExperience: state.years,
        address: state.address,
        lat: location?['lat'],
        long: location?['lng'],
        profilePic: state.profileImage,
        workToolsImage: state.toolsImage,
        previousWorkImage: state.workImage,
        workCertificate: null,
        ninImage: state.ninImage,
        isVerified: false,
        isSuspended: false,
      );

      await firestore.saveTechnician(tech);

      ref.read(authProvider.notifier).setUser(tech);

      await clearDraft();

      state = state.copyWith(isLoading: false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TechnicianMainScreen()),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}