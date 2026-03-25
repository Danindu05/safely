import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';

class MedicalProfile {
  const MedicalProfile({
    required this.userId,
    required this.fullName,
    required this.bloodGroup,
    required this.allergies,
    required this.medicalConditions,
    required this.emergencyNotes,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.updatedAt,
  });

  final String userId;
  final String fullName;
  final String bloodGroup;
  final String allergies;
  final String medicalConditions;
  final String emergencyNotes;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final DateTime updatedAt;

  factory MedicalProfile.empty(String userId) {
    return MedicalProfile(
      userId: userId,
      fullName: '',
      bloodGroup: '',
      allergies: '',
      medicalConditions: '',
      emergencyNotes: '',
      emergencyContactName: '',
      emergencyContactPhone: '',
      updatedAt: DateTime.now(),
    );
  }

  factory MedicalProfile.fromMap(Map<String, dynamic> map) {
    return MedicalProfile(
      userId: (map[FirestoreFields.userId] as String?)?.trim() ?? '',
      fullName: (map[FirestoreFields.fullName] as String?)?.trim() ?? '',
      bloodGroup: (map[FirestoreFields.bloodGroup] as String?)?.trim() ?? '',
      allergies: (map[FirestoreFields.allergies] as String?)?.trim() ?? '',
      medicalConditions:
          (map[FirestoreFields.medicalConditions] as String?)?.trim() ?? '',
      emergencyNotes:
          (map[FirestoreFields.emergencyNotes] as String?)?.trim() ?? '',
      emergencyContactName:
          (map[FirestoreFields.emergencyContactName] as String?)?.trim() ?? '',
      emergencyContactPhone:
          (map[FirestoreFields.emergencyContactPhone] as String?)?.trim() ?? '',
      updatedAt:
          (map[FirestoreFields.updatedAt] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      FirestoreFields.userId: userId,
      FirestoreFields.fullName: fullName,
      FirestoreFields.bloodGroup: bloodGroup,
      FirestoreFields.allergies: allergies,
      FirestoreFields.medicalConditions: medicalConditions,
      FirestoreFields.emergencyNotes: emergencyNotes,
      FirestoreFields.emergencyContactName: emergencyContactName,
      FirestoreFields.emergencyContactPhone: emergencyContactPhone,
      FirestoreFields.updatedAt: Timestamp.fromDate(updatedAt),
    };
  }

  MedicalProfile copyWith({
    String? fullName,
    String? bloodGroup,
    String? allergies,
    String? medicalConditions,
    String? emergencyNotes,
    String? emergencyContactName,
    String? emergencyContactPhone,
    DateTime? updatedAt,
  }) {
    return MedicalProfile(
      userId: userId,
      fullName: fullName ?? this.fullName,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      emergencyNotes: emergencyNotes ?? this.emergencyNotes,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
