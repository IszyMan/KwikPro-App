import 'package:image_picker/image_picker.dart';

class TechnicianSignupState {
  final int step;
  final String name;
  final String? service;
  final int years;
  final String address;
  final String? profileImage;
  final String? toolsImage;
  final String? workImage;
  final String? ninImage;

  final bool isLoading;

  TechnicianSignupState({
    this.step = 0,
    this.name = '',
    this.service = '',
    this.years = 0,
    this.address = '',
    this.profileImage,
    this.toolsImage,
    this.workImage,
    this.ninImage,
    this.isLoading = false,
  });

  TechnicianSignupState copyWith({
    int? step,
    String? name,
    String? service,
    int? years,
    String? address,
    String? profileImage,
    String? toolsImage,
    String? workImage,
    String? ninImage,
    bool? isLoading,
  }) {
    return TechnicianSignupState(
      step: step ?? this.step,
      name: name ?? this.name,
      service: service ?? this.service,
      years: years ?? this.years,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      toolsImage: toolsImage ?? this.toolsImage,
      workImage: workImage ?? this.workImage,
      ninImage: ninImage ?? this.ninImage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}