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


  void setName(String name) {
    state = state.copyWith(name: name);
    saveDraft();
  }

  void setService(String? service) {
    if (state.service != service) {
      state = state.copyWith(service: service, skills: []);
    }
    saveDraft();
  }

  void setSkills(List<String> skills) {
    state = state.copyWith(skills: skills);
    saveDraft();
  }

  void setWorkDetails(int years, String address) {
    state = state.copyWith(years: years, address: address);
    saveDraft();
  }

  /// ADD IMAGE
  void addImage({
    required String type,
    required String path,
  }) {
    if (type == "tools") {
      final updated = [...state.toolsImages, path];

      state = state.copyWith(
        toolsImages: updated,
      );
    }

    else if (type == "work") {
      final updated = [...state.workImages, path];

      state = state.copyWith(
        workImages: updated,
      );
    }

    else if (type == "profile") {
      state = state.copyWith(
        profileImage: path,
      );
    }

    else if (type == "nin") {
      state = state.copyWith(
        ninImage: path,
      );
    }

    saveDraft();
  }

  /// REMOVE IMAGE
  void removeImage({
    required String type,
    required String path,
  }) {

    if (type == "tools") {
      final updated =
      state.toolsImages.where((e) => e != path).toList();

      state = state.copyWith(
        toolsImages: updated,
      );
    }

    else if (type == "work") {
      final updated =
      state.workImages.where((e) => e != path).toList();

      state = state.copyWith(
        workImages: updated,
      );
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
      "skills": state.skills,
      "years": state.years,
      "address": state.address,
      "profileImage": state.profileImage,
      "toolsImages": state.toolsImages,
      "workImages": state.workImages,
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
        skills: List<String>.from(decoded["skills"] ?? []),
        years: decoded["years"],
        address: decoded["address"],
        profileImage: decoded["profileImage"],
        toolsImages:
        List<String>.from(decoded["toolsImages"] ?? []),

        workImages:
        List<String>.from(decoded["workImages"] ?? []),
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
        skills: state.skills,
        yearsOfExperience: state.years,
        address: state.address,
        lat: location?['lat'],
        long: location?['lng'],
        profilePic: state.profileImage,
        workToolsImages: state.toolsImages,
        previousWorkImages: state.workImages,
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