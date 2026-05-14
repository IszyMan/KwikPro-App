import 'package:image_picker/image_picker.dart';

class TechnicianSignupState {
  final int step;
  final String name;
  final String? service;
  final List<String> skills;
  final int years;
  final String address;
  final String? profileImage;
  final List<String> toolsImages;
  final List<String> workImages;
  final String? ninImage;

  final bool isLoading;

  TechnicianSignupState({
    this.step = 0,
    this.name = '',
    this.service = '',
    this.skills = const [],
    this.years = 0,
    this.address = '',
    this.profileImage,
    this.toolsImages = const [],
    this.workImages = const [],
    this.ninImage,
    this.isLoading = false,
  });

  TechnicianSignupState copyWith({
    int? step,
    String? name,
    String? service,
    List<String>? skills,
    int? years,
    String? address,
    String? profileImage,
    List<String>? toolsImages,
    List<String>? workImages,
    String? ninImage,
    bool? isLoading,
  }) {
    return TechnicianSignupState(
      step: step ?? this.step,
      name: name ?? this.name,
      service: service ?? this.service,
      skills: skills ?? this.skills,
      years: years ?? this.years,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      toolsImages: toolsImages ?? this.toolsImages,
      workImages: workImages ?? this.workImages,
      ninImage: ninImage ?? this.ninImage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}